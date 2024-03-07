;;; prologue-1.asm
;;; The first part of the standard prologue for compiled programs
;;;
;;; Programmer: Mayer Goldberg, 2023

%define T_void 				0
%define T_nil 				1
%define T_char 				2
%define T_string 			3
%define T_closure 			4
%define T_undefined			5
%define T_boolean 			8
%define T_boolean_false 		(T_boolean | 1)
%define T_boolean_true 			(T_boolean | 2)
%define T_number 			16
%define T_integer			(T_number | 1)
%define T_fraction 			(T_number | 2)
%define T_real 				(T_number | 3)
%define T_collection 			32
%define T_pair 				(T_collection | 1)
%define T_vector 			(T_collection | 2)
%define T_symbol 			64
%define T_interned_symbol		(T_symbol | 1)
%define T_uninterned_symbol		(T_symbol | 2)

%define SOB_CHAR_VALUE(reg) 		byte [reg + 1]
%define SOB_PAIR_CAR(reg)		qword [reg + 1]
%define SOB_PAIR_CDR(reg)		qword [reg + 1 + 8]
%define SOB_STRING_LENGTH(reg)		qword [reg + 1]
%define SOB_VECTOR_LENGTH(reg)		qword [reg + 1]
%define SOB_CLOSURE_ENV(reg)		qword [reg + 1]
%define SOB_CLOSURE_CODE(reg)		qword [reg + 1 + 8]

%define OLD_RDP 			qword [rbp]
%define RET_ADDR 			qword [rbp + 8 * 1]
%define ENV 				qword [rbp + 8 * 2]
%define COUNT 				qword [rbp + 8 * 3]
%define PARAM(n) 			qword [rbp + 8 * (4 + n)]
%define AND_KILL_FRAME(n)		(8 * (2 + n))

%define MAGIC				496351

%macro ENTER 0
	enter 0, 0
	and rsp, ~15
%endmacro

%macro LEAVE 0
	leave
%endmacro

%macro assert_type 2
        cmp byte [%1], %2
        jne L_error_incorrect_type
%endmacro

%define assert_void(reg)		assert_type reg, T_void
%define assert_nil(reg)			assert_type reg, T_nil
%define assert_char(reg)		assert_type reg, T_char
%define assert_string(reg)		assert_type reg, T_string
%define assert_symbol(reg)		assert_type reg, T_symbol
%define assert_interned_symbol(reg)	assert_type reg, T_interned_symbol
%define assert_uninterned_symbol(reg)	assert_type reg, T_uninterned_symbol
%define assert_closure(reg)		assert_type reg, T_closure
%define assert_boolean(reg)		assert_type reg, T_boolean
%define assert_integer(reg)		assert_type reg, T_integer
%define assert_fraction(reg)		assert_type reg, T_fraction
%define assert_real(reg)		assert_type reg, T_real
%define assert_pair(reg)		assert_type reg, T_pair
%define assert_vector(reg)		assert_type reg, T_vector

%define sob_void			(L_constants + 0)
%define sob_nil				(L_constants + 1)
%define sob_boolean_false		(L_constants + 2)
%define sob_boolean_true		(L_constants + 3)
%define sob_char_nul			(L_constants + 4)

%define bytes(n)			(n)
%define kbytes(n) 			(bytes(n) << 10)
%define mbytes(n) 			(kbytes(n) << 10)
%define gbytes(n) 			(mbytes(n) << 10)

section .data
L_constants:
	; L_constants + 0:
	db T_void
	; L_constants + 1:
	db T_nil
	; L_constants + 2:
	db T_boolean_false
	; L_constants + 3:
	db T_boolean_true
	; L_constants + 4:
	db T_char, 0x00	; #\nul
	; L_constants + 6:
	db T_string	; "null?"
	dq 5
	db 0x6E, 0x75, 0x6C, 0x6C, 0x3F
	; L_constants + 20:
	db T_string	; "pair?"
	dq 5
	db 0x70, 0x61, 0x69, 0x72, 0x3F
	; L_constants + 34:
	db T_string	; "void?"
	dq 5
	db 0x76, 0x6F, 0x69, 0x64, 0x3F
	; L_constants + 48:
	db T_string	; "char?"
	dq 5
	db 0x63, 0x68, 0x61, 0x72, 0x3F
	; L_constants + 62:
	db T_string	; "string?"
	dq 7
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3F
	; L_constants + 78:
	db T_string	; "interned-symbol?"
	dq 16
	db 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E, 0x65, 0x64
	db 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 103:
	db T_string	; "vector?"
	dq 7
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x3F
	; L_constants + 119:
	db T_string	; "procedure?"
	dq 10
	db 0x70, 0x72, 0x6F, 0x63, 0x65, 0x64, 0x75, 0x72
	db 0x65, 0x3F
	; L_constants + 138:
	db T_string	; "real?"
	dq 5
	db 0x72, 0x65, 0x61, 0x6C, 0x3F
	; L_constants + 152:
	db T_string	; "fraction?"
	dq 9
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x3F
	; L_constants + 170:
	db T_string	; "boolean?"
	dq 8
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x3F
	; L_constants + 187:
	db T_string	; "number?"
	dq 7
	db 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x3F
	; L_constants + 203:
	db T_string	; "collection?"
	dq 11
	db 0x63, 0x6F, 0x6C, 0x6C, 0x65, 0x63, 0x74, 0x69
	db 0x6F, 0x6E, 0x3F
	; L_constants + 223:
	db T_string	; "cons"
	dq 4
	db 0x63, 0x6F, 0x6E, 0x73
	; L_constants + 236:
	db T_string	; "display-sexpr"
	dq 13
	db 0x64, 0x69, 0x73, 0x70, 0x6C, 0x61, 0x79, 0x2D
	db 0x73, 0x65, 0x78, 0x70, 0x72
	; L_constants + 258:
	db T_string	; "write-char"
	dq 10
	db 0x77, 0x72, 0x69, 0x74, 0x65, 0x2D, 0x63, 0x68
	db 0x61, 0x72
	; L_constants + 277:
	db T_string	; "car"
	dq 3
	db 0x63, 0x61, 0x72
	; L_constants + 289:
	db T_string	; "cdr"
	dq 3
	db 0x63, 0x64, 0x72
	; L_constants + 301:
	db T_string	; "string-length"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 323:
	db T_string	; "vector-length"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 345:
	db T_string	; "real->integer"
	dq 13
	db 0x72, 0x65, 0x61, 0x6C, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 367:
	db T_string	; "exit"
	dq 4
	db 0x65, 0x78, 0x69, 0x74
	; L_constants + 380:
	db T_string	; "integer->real"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 402:
	db T_string	; "fraction->real"
	dq 14
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x2D, 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 425:
	db T_string	; "char->integer"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 447:
	db T_string	; "integer->char"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x63, 0x68, 0x61, 0x72
	; L_constants + 469:
	db T_string	; "trng"
	dq 4
	db 0x74, 0x72, 0x6E, 0x67
	; L_constants + 482:
	db T_string	; "zero?"
	dq 5
	db 0x7A, 0x65, 0x72, 0x6F, 0x3F
	; L_constants + 496:
	db T_string	; "integer?"
	dq 8
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x3F
	; L_constants + 513:
	db T_string	; "__bin-apply"
	dq 11
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x70
	db 0x70, 0x6C, 0x79
	; L_constants + 533:
	db T_string	; "__bin-add-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x72, 0x72
	; L_constants + 554:
	db T_string	; "__bin-sub-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x72, 0x72
	; L_constants + 575:
	db T_string	; "__bin-mul-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 596:
	db T_string	; "__bin-div-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x72, 0x72
	; L_constants + 617:
	db T_string	; "__bin-add-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x71, 0x71
	; L_constants + 638:
	db T_string	; "__bin-sub-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x71, 0x71
	; L_constants + 659:
	db T_string	; "__bin-mul-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 680:
	db T_string	; "__bin-div-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x71, 0x71
	; L_constants + 701:
	db T_string	; "__bin-add-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x7A, 0x7A
	; L_constants + 722:
	db T_string	; "__bin-sub-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x7A, 0x7A
	; L_constants + 743:
	db T_string	; "__bin-mul-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 764:
	db T_string	; "__bin-div-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x7A, 0x7A
	; L_constants + 785:
	db T_string	; "error"
	dq 5
	db 0x65, 0x72, 0x72, 0x6F, 0x72
	; L_constants + 799:
	db T_string	; "__bin-less-than-rr"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x72, 0x72
	; L_constants + 826:
	db T_string	; "__bin-less-than-qq"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x71, 0x71
	; L_constants + 853:
	db T_string	; "__bin-less-than-zz"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x7A, 0x7A
	; L_constants + 880:
	db T_string	; "__bin-equal-rr"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 903:
	db T_string	; "__bin-equal-qq"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 926:
	db T_string	; "__bin-equal-zz"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 949:
	db T_string	; "quotient"
	dq 8
	db 0x71, 0x75, 0x6F, 0x74, 0x69, 0x65, 0x6E, 0x74
	; L_constants + 966:
	db T_string	; "remainder"
	dq 9
	db 0x72, 0x65, 0x6D, 0x61, 0x69, 0x6E, 0x64, 0x65
	db 0x72
	; L_constants + 984:
	db T_string	; "set-car!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x61, 0x72, 0x21
	; L_constants + 1001:
	db T_string	; "set-cdr!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x64, 0x72, 0x21
	; L_constants + 1018:
	db T_string	; "string-ref"
	dq 10
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1037:
	db T_string	; "vector-ref"
	dq 10
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1056:
	db T_string	; "vector-set!"
	dq 11
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1076:
	db T_string	; "string-set!"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1096:
	db T_string	; "make-vector"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72
	; L_constants + 1116:
	db T_string	; "make-string"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67
	; L_constants + 1136:
	db T_string	; "numerator"
	dq 9
	db 0x6E, 0x75, 0x6D, 0x65, 0x72, 0x61, 0x74, 0x6F
	db 0x72
	; L_constants + 1154:
	db T_string	; "denominator"
	dq 11
	db 0x64, 0x65, 0x6E, 0x6F, 0x6D, 0x69, 0x6E, 0x61
	db 0x74, 0x6F, 0x72
	; L_constants + 1174:
	db T_string	; "eq?"
	dq 3
	db 0x65, 0x71, 0x3F
	; L_constants + 1186:
	db T_string	; "__integer-to-fracti...
	dq 21
	db 0x5F, 0x5F, 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65
	db 0x72, 0x2D, 0x74, 0x6F, 0x2D, 0x66, 0x72, 0x61
	db 0x63, 0x74, 0x69, 0x6F, 0x6E
	; L_constants + 1216:
	db T_string	; "logand"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x61, 0x6E, 0x64
	; L_constants + 1231:
	db T_string	; "logor"
	dq 5
	db 0x6C, 0x6F, 0x67, 0x6F, 0x72
	; L_constants + 1245:
	db T_string	; "logxor"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x78, 0x6F, 0x72
	; L_constants + 1260:
	db T_string	; "lognot"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x6E, 0x6F, 0x74
	; L_constants + 1275:
	db T_string	; "ash"
	dq 3
	db 0x61, 0x73, 0x68
	; L_constants + 1287:
	db T_string	; "symbol?"
	dq 7
	db 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 1303:
	db T_string	; "uninterned-symbol?"
	dq 18
	db 0x75, 0x6E, 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E
	db 0x65, 0x64, 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F
	db 0x6C, 0x3F
	; L_constants + 1330:
	db T_string	; "gensym?"
	dq 7
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D, 0x3F
	; L_constants + 1346:
	db T_string	; "gensym"
	dq 6
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D
	; L_constants + 1361:
	db T_string	; "frame"
	dq 5
	db 0x66, 0x72, 0x61, 0x6D, 0x65
	; L_constants + 1375:
	db T_string	; "break"
	dq 5
	db 0x62, 0x72, 0x65, 0x61, 0x6B
	; L_constants + 1389:
	db T_string	; "caar"
	dq 4
	db 0x63, 0x61, 0x61, 0x72
	; L_constants + 1402:
	db T_string	; "cadr"
	dq 4
	db 0x63, 0x61, 0x64, 0x72
	; L_constants + 1415:
	db T_string	; "cdar"
	dq 4
	db 0x63, 0x64, 0x61, 0x72
	; L_constants + 1428:
	db T_string	; "cddr"
	dq 4
	db 0x63, 0x64, 0x64, 0x72
	; L_constants + 1441:
	db T_string	; "caaar"
	dq 5
	db 0x63, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1455:
	db T_string	; "caadr"
	dq 5
	db 0x63, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1469:
	db T_string	; "cadar"
	dq 5
	db 0x63, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1483:
	db T_string	; "caddr"
	dq 5
	db 0x63, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1497:
	db T_string	; "cdaar"
	dq 5
	db 0x63, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1511:
	db T_string	; "cdadr"
	dq 5
	db 0x63, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1525:
	db T_string	; "cddar"
	dq 5
	db 0x63, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1539:
	db T_string	; "cdddr"
	dq 5
	db 0x63, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1553:
	db T_string	; "caaaar"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1568:
	db T_string	; "caaadr"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1583:
	db T_string	; "caadar"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1598:
	db T_string	; "caaddr"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1613:
	db T_string	; "cadaar"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1628:
	db T_string	; "cadadr"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1643:
	db T_string	; "caddar"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1658:
	db T_string	; "cadddr"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1673:
	db T_string	; "cdaaar"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1688:
	db T_string	; "cdaadr"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1703:
	db T_string	; "cdadar"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1718:
	db T_string	; "cdaddr"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1733:
	db T_string	; "cddaar"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1748:
	db T_string	; "cddadr"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1763:
	db T_string	; "cdddar"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1778:
	db T_string	; "cddddr"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1793:
	db T_string	; "list?"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x3F
	; L_constants + 1807:
	db T_string	; "list"
	dq 4
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 1820:
	db T_string	; "not"
	dq 3
	db 0x6E, 0x6F, 0x74
	; L_constants + 1832:
	db T_string	; "rational?"
	dq 9
	db 0x72, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x61, 0x6C
	db 0x3F
	; L_constants + 1850:
	db T_string	; "list*"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x2A
	; L_constants + 1864:
	db T_string	; "whatever"
	dq 8
	db 0x77, 0x68, 0x61, 0x74, 0x65, 0x76, 0x65, 0x72
	; L_constants + 1881:
	db T_interned_symbol	; whatever
	dq L_constants + 1864
	; L_constants + 1890:
	db T_string	; "apply"
	dq 5
	db 0x61, 0x70, 0x70, 0x6C, 0x79
	; L_constants + 1904:
	db T_string	; "ormap"
	dq 5
	db 0x6F, 0x72, 0x6D, 0x61, 0x70
	; L_constants + 1918:
	db T_string	; "map"
	dq 3
	db 0x6D, 0x61, 0x70
	; L_constants + 1930:
	db T_string	; "andmap"
	dq 6
	db 0x61, 0x6E, 0x64, 0x6D, 0x61, 0x70
	; L_constants + 1945:
	db T_string	; "reverse"
	dq 7
	db 0x72, 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 1961:
	db T_string	; "fold-left"
	dq 9
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x6C, 0x65, 0x66
	db 0x74
	; L_constants + 1979:
	db T_string	; "append"
	dq 6
	db 0x61, 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 1994:
	db T_string	; "fold-right"
	dq 10
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x72, 0x69, 0x67
	db 0x68, 0x74
	; L_constants + 2013:
	db T_string	; "+"
	dq 1
	db 0x2B
	; L_constants + 2023:
	db T_integer	; 0
	dq 0
	; L_constants + 2032:
	db T_string	; "__bin_integer_to_fr...
	dq 25
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x5F, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72, 0x5F, 0x74, 0x6F
	db 0x5F, 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F
	db 0x6E
	; L_constants + 2066:
	db T_interned_symbol	; +
	dq L_constants + 2013
	; L_constants + 2075:
	db T_string	; "all arguments need ...
	dq 32
	db 0x61, 0x6C, 0x6C, 0x20, 0x61, 0x72, 0x67, 0x75
	db 0x6D, 0x65, 0x6E, 0x74, 0x73, 0x20, 0x6E, 0x65
	db 0x65, 0x64, 0x20, 0x74, 0x6F, 0x20, 0x62, 0x65
	db 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x73
	; L_constants + 2116:
	db T_string	; "-"
	dq 1
	db 0x2D
	; L_constants + 2126:
	db T_string	; "real"
	dq 4
	db 0x72, 0x65, 0x61, 0x6C
	; L_constants + 2139:
	db T_interned_symbol	; -
	dq L_constants + 2116
	; L_constants + 2148:
	db T_string	; "*"
	dq 1
	db 0x2A
	; L_constants + 2158:
	db T_integer	; 1
	dq 1
	; L_constants + 2167:
	db T_interned_symbol	; *
	dq L_constants + 2148
	; L_constants + 2176:
	db T_string	; "/"
	dq 1
	db 0x2F
	; L_constants + 2186:
	db T_interned_symbol	; /
	dq L_constants + 2176
	; L_constants + 2195:
	db T_string	; "fact"
	dq 4
	db 0x66, 0x61, 0x63, 0x74
	; L_constants + 2208:
	db T_string	; "<"
	dq 1
	db 0x3C
	; L_constants + 2218:
	db T_string	; "<="
	dq 2
	db 0x3C, 0x3D
	; L_constants + 2229:
	db T_string	; ">"
	dq 1
	db 0x3E
	; L_constants + 2239:
	db T_string	; ">="
	dq 2
	db 0x3E, 0x3D
	; L_constants + 2250:
	db T_string	; "="
	dq 1
	db 0x3D
	; L_constants + 2260:
	db T_string	; "generic-comparator"
	dq 18
	db 0x67, 0x65, 0x6E, 0x65, 0x72, 0x69, 0x63, 0x2D
	db 0x63, 0x6F, 0x6D, 0x70, 0x61, 0x72, 0x61, 0x74
	db 0x6F, 0x72
	; L_constants + 2287:
	db T_interned_symbol	; generic-comparator
	dq L_constants + 2260
	; L_constants + 2296:
	db T_string	; "all the arguments m...
	dq 33
	db 0x61, 0x6C, 0x6C, 0x20, 0x74, 0x68, 0x65, 0x20
	db 0x61, 0x72, 0x67, 0x75, 0x6D, 0x65, 0x6E, 0x74
	db 0x73, 0x20, 0x6D, 0x75, 0x73, 0x74, 0x20, 0x62
	db 0x65, 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72
	db 0x73
	; L_constants + 2338:
	db T_string	; "make-list"
	dq 9
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74
	; L_constants + 2356:
	db T_interned_symbol	; make-list
	dq L_constants + 2338
	; L_constants + 2365:
	db T_string	; "Usage: (make-list l...
	dq 45
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74, 0x20, 0x6C, 0x65, 0x6E, 0x67, 0x74, 0x68
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x69, 0x6E, 0x69, 0x74, 0x2D
	db 0x63, 0x68, 0x61, 0x72, 0x29
	; L_constants + 2419:
	db T_string	; "char<?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3C, 0x3F
	; L_constants + 2434:
	db T_string	; "char<=?"
	dq 7
	db 0x63, 0x68, 0x61, 0x72, 0x3C, 0x3D, 0x3F
	; L_constants + 2450:
	db T_string	; "char=?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3D, 0x3F
	; L_constants + 2465:
	db T_string	; "char>?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3E, 0x3F
	; L_constants + 2480:
	db T_string	; "char>=?"
	dq 7
	db 0x63, 0x68, 0x61, 0x72, 0x3E, 0x3D, 0x3F
	; L_constants + 2496:
	db T_string	; "char-downcase"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x64, 0x6F, 0x77
	db 0x6E, 0x63, 0x61, 0x73, 0x65
	; L_constants + 2518:
	db T_string	; "char-upcase"
	dq 11
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x75, 0x70, 0x63
	db 0x61, 0x73, 0x65
	; L_constants + 2538:
	db T_char, 0x41	; #\A
	; L_constants + 2540:
	db T_char, 0x5A	; #\Z
	; L_constants + 2542:
	db T_char, 0x61	; #\a
	; L_constants + 2544:
	db T_char, 0x7A	; #\z
	; L_constants + 2546:
	db T_string	; "char-ci<?"
	dq 9
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3C
	db 0x3F
	; L_constants + 2564:
	db T_string	; "char-ci<=?"
	dq 10
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3C
	db 0x3D, 0x3F
	; L_constants + 2583:
	db T_string	; "char-ci=?"
	dq 9
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3D
	db 0x3F
	; L_constants + 2601:
	db T_string	; "char-ci>?"
	dq 9
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3E
	db 0x3F
	; L_constants + 2619:
	db T_string	; "char-ci>=?"
	dq 10
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3E
	db 0x3D, 0x3F
	; L_constants + 2638:
	db T_string	; "string-downcase"
	dq 15
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x64
	db 0x6F, 0x77, 0x6E, 0x63, 0x61, 0x73, 0x65
	; L_constants + 2662:
	db T_string	; "string-upcase"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x75
	db 0x70, 0x63, 0x61, 0x73, 0x65
	; L_constants + 2684:
	db T_string	; "list->string"
	dq 12
	db 0x6C, 0x69, 0x73, 0x74, 0x2D, 0x3E, 0x73, 0x74
	db 0x72, 0x69, 0x6E, 0x67
	; L_constants + 2705:
	db T_string	; "string->list"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x3E
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 2726:
	db T_string	; "string<?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3C, 0x3F
	; L_constants + 2743:
	db T_string	; "string<=?"
	dq 9
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3C, 0x3D
	db 0x3F
	; L_constants + 2761:
	db T_string	; "string=?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3D, 0x3F
	; L_constants + 2778:
	db T_string	; "string>=?"
	dq 9
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3E, 0x3D
	db 0x3F
	; L_constants + 2796:
	db T_string	; "string>?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3E, 0x3F
	; L_constants + 2813:
	db T_string	; "string-ci<?"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3C, 0x3F
	; L_constants + 2833:
	db T_string	; "string-ci<=?"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3C, 0x3D, 0x3F
	; L_constants + 2854:
	db T_string	; "string-ci=?"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3D, 0x3F
	; L_constants + 2874:
	db T_string	; "string-ci>=?"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3E, 0x3D, 0x3F
	; L_constants + 2895:
	db T_string	; "string-ci>?"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3E, 0x3F
	; L_constants + 2915:
	db T_string	; "length"
	dq 6
	db 0x6C, 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 2930:
	db T_interned_symbol	; make-vector
	dq L_constants + 1096
	; L_constants + 2939:
	db T_string	; "Usage: (make-vector...
	dq 43
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72, 0x20, 0x73, 0x69, 0x7A, 0x65
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x64, 0x65, 0x66, 0x61, 0x75
	db 0x6C, 0x74, 0x29
	; L_constants + 2991:
	db T_interned_symbol	; make-string
	dq L_constants + 1116
	; L_constants + 3000:
	db T_string	; "Usage: (make-string...
	dq 43
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67, 0x20, 0x73, 0x69, 0x7A, 0x65
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x64, 0x65, 0x66, 0x61, 0x75
	db 0x6C, 0x74, 0x29
	; L_constants + 3052:
	db T_string	; "list->vector"
	dq 12
	db 0x6C, 0x69, 0x73, 0x74, 0x2D, 0x3E, 0x76, 0x65
	db 0x63, 0x74, 0x6F, 0x72
	; L_constants + 3073:
	db T_string	; "vector"
	dq 6
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72
	; L_constants + 3088:
	db T_string	; "vector->list"
	dq 12
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x3E
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 3109:
	db T_string	; "random"
	dq 6
	db 0x72, 0x61, 0x6E, 0x64, 0x6F, 0x6D
	; L_constants + 3124:
	db T_string	; "positive?"
	dq 9
	db 0x70, 0x6F, 0x73, 0x69, 0x74, 0x69, 0x76, 0x65
	db 0x3F
	; L_constants + 3142:
	db T_string	; "negative?"
	dq 9
	db 0x6E, 0x65, 0x67, 0x61, 0x74, 0x69, 0x76, 0x65
	db 0x3F
	; L_constants + 3160:
	db T_string	; "even?"
	dq 5
	db 0x65, 0x76, 0x65, 0x6E, 0x3F
	; L_constants + 3174:
	db T_integer	; 2
	dq 2
	; L_constants + 3183:
	db T_string	; "odd?"
	dq 4
	db 0x6F, 0x64, 0x64, 0x3F
	; L_constants + 3196:
	db T_string	; "abs"
	dq 3
	db 0x61, 0x62, 0x73
	; L_constants + 3208:
	db T_string	; "equal?"
	dq 6
	db 0x65, 0x71, 0x75, 0x61, 0x6C, 0x3F
	; L_constants + 3223:
	db T_string	; "assoc"
	dq 5
	db 0x61, 0x73, 0x73, 0x6F, 0x63
	; L_constants + 3237:
	db T_string	; "string-append"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x61
	db 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 3259:
	db T_string	; "vector-append"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x61
	db 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 3281:
	db T_string	; "string-reverse"
	dq 14
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 3304:
	db T_string	; "vector-reverse"
	dq 14
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 3327:
	db T_string	; "string-reverse!"
	dq 15
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65, 0x21
	; L_constants + 3351:
	db T_string	; "vector-reverse!"
	dq 15
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65, 0x21
	; L_constants + 3375:
	db T_string	; "make-list-thunk"
	dq 15
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74, 0x2D, 0x74, 0x68, 0x75, 0x6E, 0x6B
	; L_constants + 3399:
	db T_string	; "make-string-thunk"
	dq 17
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67, 0x2D, 0x74, 0x68, 0x75, 0x6E
	db 0x6B
	; L_constants + 3425:
	db T_string	; "make-vector-thunk"
	dq 17
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72, 0x2D, 0x74, 0x68, 0x75, 0x6E
	db 0x6B
	; L_constants + 3451:
	db T_string	; "logarithm"
	dq 9
	db 0x6C, 0x6F, 0x67, 0x61, 0x72, 0x69, 0x74, 0x68
	db 0x6D
	; L_constants + 3469:
	db T_real	; 1.000000
	dq 1.000000
	; L_constants + 3478:
	db T_string	; "newline"
	dq 7
	db 0x6E, 0x65, 0x77, 0x6C, 0x69, 0x6E, 0x65
	; L_constants + 3494:
	db T_char, 0x0A	; #\newline
free_var_0:	; location of null?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 6

free_var_1:	; location of pair?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 20

free_var_2:	; location of void?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 34

free_var_3:	; location of char?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 48

free_var_4:	; location of string?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 62

free_var_5:	; location of interned-symbol?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 78

free_var_6:	; location of vector?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 103

free_var_7:	; location of procedure?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 119

free_var_8:	; location of real?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 138

free_var_9:	; location of fraction?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 152

free_var_10:	; location of boolean?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 170

free_var_11:	; location of number?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 187

free_var_12:	; location of collection?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 203

free_var_13:	; location of cons
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 223

free_var_14:	; location of display-sexpr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 236

free_var_15:	; location of write-char
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 258

free_var_16:	; location of car
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 277

free_var_17:	; location of cdr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 289

free_var_18:	; location of string-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 301

free_var_19:	; location of vector-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 323

free_var_20:	; location of real->integer
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 345

free_var_21:	; location of exit
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 367

free_var_22:	; location of integer->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 380

free_var_23:	; location of fraction->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 402

free_var_24:	; location of char->integer
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 425

free_var_25:	; location of integer->char
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 447

free_var_26:	; location of trng
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 469

free_var_27:	; location of zero?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 482

free_var_28:	; location of integer?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 496

free_var_29:	; location of __bin-apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 513

free_var_30:	; location of __bin-add-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 533

free_var_31:	; location of __bin-sub-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 554

free_var_32:	; location of __bin-mul-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 575

free_var_33:	; location of __bin-div-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 596

free_var_34:	; location of __bin-add-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 617

free_var_35:	; location of __bin-sub-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 638

free_var_36:	; location of __bin-mul-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 659

free_var_37:	; location of __bin-div-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 680

free_var_38:	; location of __bin-add-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 701

free_var_39:	; location of __bin-sub-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 722

free_var_40:	; location of __bin-mul-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 743

free_var_41:	; location of __bin-div-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 764

free_var_42:	; location of error
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 785

free_var_43:	; location of __bin-less-than-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 799

free_var_44:	; location of __bin-less-than-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 826

free_var_45:	; location of __bin-less-than-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 853

free_var_46:	; location of __bin-equal-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 880

free_var_47:	; location of __bin-equal-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 903

free_var_48:	; location of __bin-equal-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 926

free_var_49:	; location of quotient
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 949

free_var_50:	; location of remainder
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 966

free_var_51:	; location of set-car!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 984

free_var_52:	; location of set-cdr!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1001

free_var_53:	; location of string-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1018

free_var_54:	; location of vector-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1037

free_var_55:	; location of vector-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1056

free_var_56:	; location of string-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1076

free_var_57:	; location of make-vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1096

free_var_58:	; location of make-string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1116

free_var_59:	; location of numerator
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1136

free_var_60:	; location of denominator
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1154

free_var_61:	; location of eq?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1174

free_var_62:	; location of __integer-to-fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1186

free_var_63:	; location of logand
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1216

free_var_64:	; location of logor
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1231

free_var_65:	; location of logxor
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1245

free_var_66:	; location of lognot
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1260

free_var_67:	; location of ash
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1275

free_var_68:	; location of symbol?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1287

free_var_69:	; location of uninterned-symbol?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1303

free_var_70:	; location of gensym?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1330

free_var_71:	; location of gensym
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1346

free_var_72:	; location of frame
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1361

free_var_73:	; location of break
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1375

free_var_74:	; location of caar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1389

free_var_75:	; location of cadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1402

free_var_76:	; location of cdar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1415

free_var_77:	; location of cddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1428

free_var_78:	; location of caaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1441

free_var_79:	; location of caadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1455

free_var_80:	; location of cadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1469

free_var_81:	; location of caddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1483

free_var_82:	; location of cdaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1497

free_var_83:	; location of cdadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1511

free_var_84:	; location of cddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1525

free_var_85:	; location of cdddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1539

free_var_86:	; location of caaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1553

free_var_87:	; location of caaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1568

free_var_88:	; location of caadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1583

free_var_89:	; location of caaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1598

free_var_90:	; location of cadaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1613

free_var_91:	; location of cadadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1628

free_var_92:	; location of caddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1643

free_var_93:	; location of cadddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1658

free_var_94:	; location of cdaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1673

free_var_95:	; location of cdaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1688

free_var_96:	; location of cdadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1703

free_var_97:	; location of cdaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1718

free_var_98:	; location of cddaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1733

free_var_99:	; location of cddadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1748

free_var_100:	; location of cdddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1763

free_var_101:	; location of cddddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1778

free_var_102:	; location of list?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1793

free_var_103:	; location of list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1807

free_var_104:	; location of not
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1820

free_var_105:	; location of rational?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1832

free_var_106:	; location of list*
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1850

free_var_107:	; location of apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1890

free_var_108:	; location of ormap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1904

free_var_109:	; location of map
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1918

free_var_110:	; location of andmap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1930

free_var_111:	; location of reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1945

free_var_112:	; location of fold-left
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1961

free_var_113:	; location of append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1979

free_var_114:	; location of fold-right
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1994

free_var_115:	; location of +
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2013

free_var_116:	; location of __bin_integer_to_fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2032

free_var_117:	; location of -
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2116

free_var_118:	; location of real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2126

free_var_119:	; location of *
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2148

free_var_120:	; location of /
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2176

free_var_121:	; location of fact
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2195

free_var_122:	; location of <
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2208

free_var_123:	; location of <=
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2218

free_var_124:	; location of >
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2229

free_var_125:	; location of >=
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2239

free_var_126:	; location of =
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2250

free_var_127:	; location of make-list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2338

free_var_128:	; location of char<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2419

free_var_129:	; location of char<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2434

free_var_130:	; location of char=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2450

free_var_131:	; location of char>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2465

free_var_132:	; location of char>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2480

free_var_133:	; location of char-downcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2496

free_var_134:	; location of char-upcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2518

free_var_135:	; location of char-ci<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2546

free_var_136:	; location of char-ci<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2564

free_var_137:	; location of char-ci=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2583

free_var_138:	; location of char-ci>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2601

free_var_139:	; location of char-ci>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2619

free_var_140:	; location of string-downcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2638

free_var_141:	; location of string-upcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2662

free_var_142:	; location of list->string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2684

free_var_143:	; location of string->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2705

free_var_144:	; location of string<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2726

free_var_145:	; location of string<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2743

free_var_146:	; location of string=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2761

free_var_147:	; location of string>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2778

free_var_148:	; location of string>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2796

free_var_149:	; location of string-ci<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2813

free_var_150:	; location of string-ci<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2833

free_var_151:	; location of string-ci=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2854

free_var_152:	; location of string-ci>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2874

free_var_153:	; location of string-ci>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2895

free_var_154:	; location of length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2915

free_var_155:	; location of list->vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3052

free_var_156:	; location of vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3073

free_var_157:	; location of vector->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3088

free_var_158:	; location of random
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3109

free_var_159:	; location of positive?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3124

free_var_160:	; location of negative?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3142

free_var_161:	; location of even?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3160

free_var_162:	; location of odd?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3183

free_var_163:	; location of abs
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3196

free_var_164:	; location of equal?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3208

free_var_165:	; location of assoc
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3223

free_var_166:	; location of string-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3237

free_var_167:	; location of vector-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3259

free_var_168:	; location of string-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3281

free_var_169:	; location of vector-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3304

free_var_170:	; location of string-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3327

free_var_171:	; location of vector-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3351

free_var_172:	; location of make-list-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3375

free_var_173:	; location of make-string-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3399

free_var_174:	; location of make-vector-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3425

free_var_175:	; location of logarithm
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3451

free_var_176:	; location of newline
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3478


extern printf, fprintf, stdout, stderr, fwrite, exit, putchar, getchar
global main
section .text
main:
        enter 0, 0
        
	; building closure for null?
	mov rdi, free_var_0
	mov rsi, L_code_ptr_is_null
	call bind_primitive

	; building closure for pair?
	mov rdi, free_var_1
	mov rsi, L_code_ptr_is_pair
	call bind_primitive

	; building closure for void?
	mov rdi, free_var_2
	mov rsi, L_code_ptr_is_void
	call bind_primitive

	; building closure for char?
	mov rdi, free_var_3
	mov rsi, L_code_ptr_is_char
	call bind_primitive

	; building closure for string?
	mov rdi, free_var_4
	mov rsi, L_code_ptr_is_string
	call bind_primitive

	; building closure for interned-symbol?
	mov rdi, free_var_5
	mov rsi, L_code_ptr_is_symbol
	call bind_primitive

	; building closure for vector?
	mov rdi, free_var_6
	mov rsi, L_code_ptr_is_vector
	call bind_primitive

	; building closure for procedure?
	mov rdi, free_var_7
	mov rsi, L_code_ptr_is_closure
	call bind_primitive

	; building closure for real?
	mov rdi, free_var_8
	mov rsi, L_code_ptr_is_real
	call bind_primitive

	; building closure for fraction?
	mov rdi, free_var_9
	mov rsi, L_code_ptr_is_fraction
	call bind_primitive

	; building closure for boolean?
	mov rdi, free_var_10
	mov rsi, L_code_ptr_is_boolean
	call bind_primitive

	; building closure for number?
	mov rdi, free_var_11
	mov rsi, L_code_ptr_is_number
	call bind_primitive

	; building closure for collection?
	mov rdi, free_var_12
	mov rsi, L_code_ptr_is_collection
	call bind_primitive

	; building closure for cons
	mov rdi, free_var_13
	mov rsi, L_code_ptr_cons
	call bind_primitive

	; building closure for display-sexpr
	mov rdi, free_var_14
	mov rsi, L_code_ptr_display_sexpr
	call bind_primitive

	; building closure for write-char
	mov rdi, free_var_15
	mov rsi, L_code_ptr_write_char
	call bind_primitive

	; building closure for car
	mov rdi, free_var_16
	mov rsi, L_code_ptr_car
	call bind_primitive

	; building closure for cdr
	mov rdi, free_var_17
	mov rsi, L_code_ptr_cdr
	call bind_primitive

	; building closure for string-length
	mov rdi, free_var_18
	mov rsi, L_code_ptr_string_length
	call bind_primitive

	; building closure for vector-length
	mov rdi, free_var_19
	mov rsi, L_code_ptr_vector_length
	call bind_primitive

	; building closure for real->integer
	mov rdi, free_var_20
	mov rsi, L_code_ptr_real_to_integer
	call bind_primitive

	; building closure for exit
	mov rdi, free_var_21
	mov rsi, L_code_ptr_exit
	call bind_primitive

	; building closure for integer->real
	mov rdi, free_var_22
	mov rsi, L_code_ptr_integer_to_real
	call bind_primitive

	; building closure for fraction->real
	mov rdi, free_var_23
	mov rsi, L_code_ptr_fraction_to_real
	call bind_primitive

	; building closure for char->integer
	mov rdi, free_var_24
	mov rsi, L_code_ptr_char_to_integer
	call bind_primitive

	; building closure for integer->char
	mov rdi, free_var_25
	mov rsi, L_code_ptr_integer_to_char
	call bind_primitive

	; building closure for trng
	mov rdi, free_var_26
	mov rsi, L_code_ptr_trng
	call bind_primitive

	; building closure for zero?
	mov rdi, free_var_27
	mov rsi, L_code_ptr_is_zero
	call bind_primitive

	; building closure for integer?
	mov rdi, free_var_28
	mov rsi, L_code_ptr_is_integer
	call bind_primitive

	; building closure for __bin-apply
	mov rdi, free_var_29
	mov rsi, L_code_ptr_bin_apply
	call bind_primitive

	; building closure for __bin-add-rr
	mov rdi, free_var_30
	mov rsi, L_code_ptr_raw_bin_add_rr
	call bind_primitive

	; building closure for __bin-sub-rr
	mov rdi, free_var_31
	mov rsi, L_code_ptr_raw_bin_sub_rr
	call bind_primitive

	; building closure for __bin-mul-rr
	mov rdi, free_var_32
	mov rsi, L_code_ptr_raw_bin_mul_rr
	call bind_primitive

	; building closure for __bin-div-rr
	mov rdi, free_var_33
	mov rsi, L_code_ptr_raw_bin_div_rr
	call bind_primitive

	; building closure for __bin-add-qq
	mov rdi, free_var_34
	mov rsi, L_code_ptr_raw_bin_add_qq
	call bind_primitive

	; building closure for __bin-sub-qq
	mov rdi, free_var_35
	mov rsi, L_code_ptr_raw_bin_sub_qq
	call bind_primitive

	; building closure for __bin-mul-qq
	mov rdi, free_var_36
	mov rsi, L_code_ptr_raw_bin_mul_qq
	call bind_primitive

	; building closure for __bin-div-qq
	mov rdi, free_var_37
	mov rsi, L_code_ptr_raw_bin_div_qq
	call bind_primitive

	; building closure for __bin-add-zz
	mov rdi, free_var_38
	mov rsi, L_code_ptr_raw_bin_add_zz
	call bind_primitive

	; building closure for __bin-sub-zz
	mov rdi, free_var_39
	mov rsi, L_code_ptr_raw_bin_sub_zz
	call bind_primitive

	; building closure for __bin-mul-zz
	mov rdi, free_var_40
	mov rsi, L_code_ptr_raw_bin_mul_zz
	call bind_primitive

	; building closure for __bin-div-zz
	mov rdi, free_var_41
	mov rsi, L_code_ptr_raw_bin_div_zz
	call bind_primitive

	; building closure for error
	mov rdi, free_var_42
	mov rsi, L_code_ptr_error
	call bind_primitive

	; building closure for __bin-less-than-rr
	mov rdi, free_var_43
	mov rsi, L_code_ptr_raw_less_than_rr
	call bind_primitive

	; building closure for __bin-less-than-qq
	mov rdi, free_var_44
	mov rsi, L_code_ptr_raw_less_than_qq
	call bind_primitive

	; building closure for __bin-less-than-zz
	mov rdi, free_var_45
	mov rsi, L_code_ptr_raw_less_than_zz
	call bind_primitive

	; building closure for __bin-equal-rr
	mov rdi, free_var_46
	mov rsi, L_code_ptr_raw_equal_rr
	call bind_primitive

	; building closure for __bin-equal-qq
	mov rdi, free_var_47
	mov rsi, L_code_ptr_raw_equal_qq
	call bind_primitive

	; building closure for __bin-equal-zz
	mov rdi, free_var_48
	mov rsi, L_code_ptr_raw_equal_zz
	call bind_primitive

	; building closure for quotient
	mov rdi, free_var_49
	mov rsi, L_code_ptr_quotient
	call bind_primitive

	; building closure for remainder
	mov rdi, free_var_50
	mov rsi, L_code_ptr_remainder
	call bind_primitive

	; building closure for set-car!
	mov rdi, free_var_51
	mov rsi, L_code_ptr_set_car
	call bind_primitive

	; building closure for set-cdr!
	mov rdi, free_var_52
	mov rsi, L_code_ptr_set_cdr
	call bind_primitive

	; building closure for string-ref
	mov rdi, free_var_53
	mov rsi, L_code_ptr_string_ref
	call bind_primitive

	; building closure for vector-ref
	mov rdi, free_var_54
	mov rsi, L_code_ptr_vector_ref
	call bind_primitive

	; building closure for vector-set!
	mov rdi, free_var_55
	mov rsi, L_code_ptr_vector_set
	call bind_primitive

	; building closure for string-set!
	mov rdi, free_var_56
	mov rsi, L_code_ptr_string_set
	call bind_primitive

	; building closure for make-vector
	mov rdi, free_var_57
	mov rsi, L_code_ptr_make_vector
	call bind_primitive

	; building closure for make-string
	mov rdi, free_var_58
	mov rsi, L_code_ptr_make_string
	call bind_primitive

	; building closure for numerator
	mov rdi, free_var_59
	mov rsi, L_code_ptr_numerator
	call bind_primitive

	; building closure for denominator
	mov rdi, free_var_60
	mov rsi, L_code_ptr_denominator
	call bind_primitive

	; building closure for eq?
	mov rdi, free_var_61
	mov rsi, L_code_ptr_is_eq
	call bind_primitive

	; building closure for __integer-to-fraction
	mov rdi, free_var_62
	mov rsi, L_code_ptr_integer_to_fraction
	call bind_primitive

	; building closure for logand
	mov rdi, free_var_63
	mov rsi, L_code_ptr_logand
	call bind_primitive

	; building closure for logor
	mov rdi, free_var_64
	mov rsi, L_code_ptr_logor
	call bind_primitive

	; building closure for logxor
	mov rdi, free_var_65
	mov rsi, L_code_ptr_logxor
	call bind_primitive

	; building closure for lognot
	mov rdi, free_var_66
	mov rsi, L_code_ptr_lognot
	call bind_primitive

	; building closure for ash
	mov rdi, free_var_67
	mov rsi, L_code_ptr_ash
	call bind_primitive

	; building closure for symbol?
	mov rdi, free_var_68
	mov rsi, L_code_ptr_is_symbol
	call bind_primitive

	; building closure for uninterned-symbol?
	mov rdi, free_var_69
	mov rsi, L_code_ptr_is_uninterned_symbol
	call bind_primitive

	; building closure for gensym?
	mov rdi, free_var_70
	mov rsi, L_code_ptr_is_uninterned_symbol
	call bind_primitive

	; building closure for interned-symbol?
	mov rdi, free_var_5
	mov rsi, L_code_ptr_is_interned_symbol
	call bind_primitive

	; building closure for gensym
	mov rdi, free_var_71
	mov rsi, L_code_ptr_gensym
	call bind_primitive

	; building closure for frame
	mov rdi, free_var_72
	mov rsi, L_code_ptr_frame
	call bind_primitive

	; building closure for break
	mov rdi, free_var_73
	mov rsi, L_code_ptr_break
	call bind_primitive

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cec:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cec
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cec
.L_lambda_simple_env_end_6cec:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cec:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cec
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cec
.L_lambda_simple_params_end_6cec:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cec
	jmp .L_lambda_simple_end_6cec
.L_lambda_simple_code_6cec:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cec
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cec:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eaa:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eaa
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eaa
.L_tc_recycle_frame_done_8eaa:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cec:	; new closure is in rax
	mov qword [free_var_74], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6ced:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6ced
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6ced
.L_lambda_simple_env_end_6ced:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6ced:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6ced
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6ced
.L_lambda_simple_params_end_6ced:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6ced
	jmp .L_lambda_simple_end_6ced
.L_lambda_simple_code_6ced:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6ced
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6ced:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eab:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eab
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eab
.L_tc_recycle_frame_done_8eab:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6ced:	; new closure is in rax
	mov qword [free_var_75], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cee:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cee
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cee
.L_lambda_simple_env_end_6cee:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cee:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cee
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cee
.L_lambda_simple_params_end_6cee:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cee
	jmp .L_lambda_simple_end_6cee
.L_lambda_simple_code_6cee:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cee
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cee:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eac:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eac
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eac
.L_tc_recycle_frame_done_8eac:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cee:	; new closure is in rax
	mov qword [free_var_76], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cef:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cef
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cef
.L_lambda_simple_env_end_6cef:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cef:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cef
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cef
.L_lambda_simple_params_end_6cef:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cef
	jmp .L_lambda_simple_end_6cef
.L_lambda_simple_code_6cef:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cef
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cef:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ead:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ead
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ead
.L_tc_recycle_frame_done_8ead:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cef:	; new closure is in rax
	mov qword [free_var_77], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cf0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cf0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cf0
.L_lambda_simple_env_end_6cf0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cf0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cf0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cf0
.L_lambda_simple_params_end_6cf0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cf0
	jmp .L_lambda_simple_end_6cf0
.L_lambda_simple_code_6cf0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cf0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cf0:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eae:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eae
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eae
.L_tc_recycle_frame_done_8eae:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cf0:	; new closure is in rax
	mov qword [free_var_78], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cf1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cf1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cf1
.L_lambda_simple_env_end_6cf1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cf1:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cf1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cf1
.L_lambda_simple_params_end_6cf1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cf1
	jmp .L_lambda_simple_end_6cf1
.L_lambda_simple_code_6cf1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cf1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cf1:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eaf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eaf
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eaf
.L_tc_recycle_frame_done_8eaf:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cf1:	; new closure is in rax
	mov qword [free_var_79], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cf2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cf2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cf2
.L_lambda_simple_env_end_6cf2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cf2:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cf2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cf2
.L_lambda_simple_params_end_6cf2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cf2
	jmp .L_lambda_simple_end_6cf2
.L_lambda_simple_code_6cf2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cf2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cf2:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eb0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eb0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eb0
.L_tc_recycle_frame_done_8eb0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cf2:	; new closure is in rax
	mov qword [free_var_80], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cf3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cf3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cf3
.L_lambda_simple_env_end_6cf3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cf3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cf3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cf3
.L_lambda_simple_params_end_6cf3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cf3
	jmp .L_lambda_simple_end_6cf3
.L_lambda_simple_code_6cf3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cf3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cf3:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eb1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eb1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eb1
.L_tc_recycle_frame_done_8eb1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cf3:	; new closure is in rax
	mov qword [free_var_81], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cf4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cf4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cf4
.L_lambda_simple_env_end_6cf4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cf4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cf4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cf4
.L_lambda_simple_params_end_6cf4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cf4
	jmp .L_lambda_simple_end_6cf4
.L_lambda_simple_code_6cf4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cf4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cf4:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eb2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eb2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eb2
.L_tc_recycle_frame_done_8eb2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cf4:	; new closure is in rax
	mov qword [free_var_82], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cf5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cf5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cf5
.L_lambda_simple_env_end_6cf5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cf5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cf5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cf5
.L_lambda_simple_params_end_6cf5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cf5
	jmp .L_lambda_simple_end_6cf5
.L_lambda_simple_code_6cf5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cf5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cf5:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eb3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eb3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eb3
.L_tc_recycle_frame_done_8eb3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cf5:	; new closure is in rax
	mov qword [free_var_83], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cf6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cf6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cf6
.L_lambda_simple_env_end_6cf6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cf6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cf6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cf6
.L_lambda_simple_params_end_6cf6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cf6
	jmp .L_lambda_simple_end_6cf6
.L_lambda_simple_code_6cf6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cf6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cf6:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eb4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eb4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eb4
.L_tc_recycle_frame_done_8eb4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cf6:	; new closure is in rax
	mov qword [free_var_84], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cf7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cf7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cf7
.L_lambda_simple_env_end_6cf7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cf7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cf7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cf7
.L_lambda_simple_params_end_6cf7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cf7
	jmp .L_lambda_simple_end_6cf7
.L_lambda_simple_code_6cf7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cf7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cf7:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eb5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eb5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eb5
.L_tc_recycle_frame_done_8eb5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cf7:	; new closure is in rax
	mov qword [free_var_85], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cf8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cf8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cf8
.L_lambda_simple_env_end_6cf8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cf8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cf8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cf8
.L_lambda_simple_params_end_6cf8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cf8
	jmp .L_lambda_simple_end_6cf8
.L_lambda_simple_code_6cf8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cf8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cf8:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eb6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eb6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eb6
.L_tc_recycle_frame_done_8eb6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cf8:	; new closure is in rax
	mov qword [free_var_86], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cf9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cf9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cf9
.L_lambda_simple_env_end_6cf9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cf9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cf9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cf9
.L_lambda_simple_params_end_6cf9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cf9
	jmp .L_lambda_simple_end_6cf9
.L_lambda_simple_code_6cf9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cf9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cf9:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eb7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eb7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eb7
.L_tc_recycle_frame_done_8eb7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cf9:	; new closure is in rax
	mov qword [free_var_87], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cfa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cfa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cfa
.L_lambda_simple_env_end_6cfa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cfa:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cfa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cfa
.L_lambda_simple_params_end_6cfa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cfa
	jmp .L_lambda_simple_end_6cfa
.L_lambda_simple_code_6cfa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cfa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cfa:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eb8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eb8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eb8
.L_tc_recycle_frame_done_8eb8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cfa:	; new closure is in rax
	mov qword [free_var_88], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cfb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cfb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cfb
.L_lambda_simple_env_end_6cfb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cfb:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cfb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cfb
.L_lambda_simple_params_end_6cfb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cfb
	jmp .L_lambda_simple_end_6cfb
.L_lambda_simple_code_6cfb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cfb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cfb:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eb9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eb9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eb9
.L_tc_recycle_frame_done_8eb9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cfb:	; new closure is in rax
	mov qword [free_var_89], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cfc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cfc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cfc
.L_lambda_simple_env_end_6cfc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cfc:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cfc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cfc
.L_lambda_simple_params_end_6cfc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cfc
	jmp .L_lambda_simple_end_6cfc
.L_lambda_simple_code_6cfc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cfc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cfc:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eba:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eba
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eba
.L_tc_recycle_frame_done_8eba:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cfc:	; new closure is in rax
	mov qword [free_var_90], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cfd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cfd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cfd
.L_lambda_simple_env_end_6cfd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cfd:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cfd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cfd
.L_lambda_simple_params_end_6cfd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cfd
	jmp .L_lambda_simple_end_6cfd
.L_lambda_simple_code_6cfd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cfd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cfd:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ebb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ebb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ebb
.L_tc_recycle_frame_done_8ebb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cfd:	; new closure is in rax
	mov qword [free_var_91], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cfe:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cfe
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cfe
.L_lambda_simple_env_end_6cfe:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cfe:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cfe
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cfe
.L_lambda_simple_params_end_6cfe:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cfe
	jmp .L_lambda_simple_end_6cfe
.L_lambda_simple_code_6cfe:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cfe
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cfe:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ebc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ebc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ebc
.L_tc_recycle_frame_done_8ebc:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cfe:	; new closure is in rax
	mov qword [free_var_92], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6cff:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6cff
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6cff
.L_lambda_simple_env_end_6cff:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6cff:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6cff
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6cff
.L_lambda_simple_params_end_6cff:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6cff
	jmp .L_lambda_simple_end_6cff
.L_lambda_simple_code_6cff:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6cff
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6cff:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ebd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ebd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ebd
.L_tc_recycle_frame_done_8ebd:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6cff:	; new closure is in rax
	mov qword [free_var_93], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d00:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d00
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d00
.L_lambda_simple_env_end_6d00:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d00:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d00
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d00
.L_lambda_simple_params_end_6d00:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d00
	jmp .L_lambda_simple_end_6d00
.L_lambda_simple_code_6d00:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d00
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d00:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ebe:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ebe
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ebe
.L_tc_recycle_frame_done_8ebe:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d00:	; new closure is in rax
	mov qword [free_var_94], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d01:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d01
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d01
.L_lambda_simple_env_end_6d01:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d01:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d01
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d01
.L_lambda_simple_params_end_6d01:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d01
	jmp .L_lambda_simple_end_6d01
.L_lambda_simple_code_6d01:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d01
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d01:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ebf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ebf
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ebf
.L_tc_recycle_frame_done_8ebf:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d01:	; new closure is in rax
	mov qword [free_var_95], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d02:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d02
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d02
.L_lambda_simple_env_end_6d02:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d02:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d02
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d02
.L_lambda_simple_params_end_6d02:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d02
	jmp .L_lambda_simple_end_6d02
.L_lambda_simple_code_6d02:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d02
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d02:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ec0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ec0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ec0
.L_tc_recycle_frame_done_8ec0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d02:	; new closure is in rax
	mov qword [free_var_96], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d03:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d03
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d03
.L_lambda_simple_env_end_6d03:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d03:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d03
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d03
.L_lambda_simple_params_end_6d03:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d03
	jmp .L_lambda_simple_end_6d03
.L_lambda_simple_code_6d03:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d03
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d03:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ec1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ec1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ec1
.L_tc_recycle_frame_done_8ec1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d03:	; new closure is in rax
	mov qword [free_var_97], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d04:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d04
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d04
.L_lambda_simple_env_end_6d04:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d04:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d04
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d04
.L_lambda_simple_params_end_6d04:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d04
	jmp .L_lambda_simple_end_6d04
.L_lambda_simple_code_6d04:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d04
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d04:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ec2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ec2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ec2
.L_tc_recycle_frame_done_8ec2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d04:	; new closure is in rax
	mov qword [free_var_98], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d05:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d05
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d05
.L_lambda_simple_env_end_6d05:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d05:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d05
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d05
.L_lambda_simple_params_end_6d05:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d05
	jmp .L_lambda_simple_end_6d05
.L_lambda_simple_code_6d05:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d05
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d05:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ec3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ec3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ec3
.L_tc_recycle_frame_done_8ec3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d05:	; new closure is in rax
	mov qword [free_var_99], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d06:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d06
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d06
.L_lambda_simple_env_end_6d06:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d06:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d06
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d06
.L_lambda_simple_params_end_6d06:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d06
	jmp .L_lambda_simple_end_6d06
.L_lambda_simple_code_6d06:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d06
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d06:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ec4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ec4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ec4
.L_tc_recycle_frame_done_8ec4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d06:	; new closure is in rax
	mov qword [free_var_100], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d07:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d07
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d07
.L_lambda_simple_env_end_6d07:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d07:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d07
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d07
.L_lambda_simple_params_end_6d07:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d07
	jmp .L_lambda_simple_end_6d07
.L_lambda_simple_code_6d07:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d07
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d07:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ec5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ec5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ec5
.L_tc_recycle_frame_done_8ec5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d07:	; new closure is in rax
	mov qword [free_var_101], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d08:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d08
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d08
.L_lambda_simple_env_end_6d08:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d08:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d08
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d08
.L_lambda_simple_params_end_6d08:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d08
	jmp .L_lambda_simple_end_6d08
.L_lambda_simple_code_6d08:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d08
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d08:
	enter 0, 0
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0770
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76c0
	; preparing a tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_102]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ec6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ec6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ec6
.L_tc_recycle_frame_done_8ec6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76c0

	.L_if_else_76c0:
	mov rax, L_constants + 2

	.L_if_end_76c0:
.L_or_end_0770:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d08:	; new closure is in rax
	mov qword [free_var_102], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f51:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_0f51
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f51
.L_lambda_opt_env_end_0f51:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f51:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_0f51
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f51
.L_lambda_opt_params_end_0f51:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f51
	jmp .L_lambda_opt_end_0f51
.L_lambda_opt_code_0f51:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f51 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f51 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f51:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f51:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f51
	.L_lambda_opt_exact_shifting_loop_end_0f51:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f51
	.L_lambda_opt_arity_check_more_0f51:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f51
	.L_lambda_opt_stack_shrink_loop_0f51:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f51:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f51
	.L_lambda_opt_more_shifting_loop_end_0f51:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_0f51
	.L_lambda_opt_stack_shrink_loop_exit_0f51:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f51:
	enter 0, 0
	mov rax, PARAM(0)	; param args
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0f51:	; new closure is in rax
	mov qword [free_var_103], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d09:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d09
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d09
.L_lambda_simple_env_end_6d09:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d09:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d09
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d09
.L_lambda_simple_params_end_6d09:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d09
	jmp .L_lambda_simple_end_6d09
.L_lambda_simple_code_6d09:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d09
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d09:
	enter 0, 0
	mov rax, PARAM(0)	; param x

	cmp rax, sob_boolean_false
	je .L_if_else_76c1
	mov rax, L_constants + 2

	jmp .L_if_end_76c1

	.L_if_else_76c1:
	mov rax, L_constants + 3

	.L_if_end_76c1:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d09:	; new closure is in rax
	mov qword [free_var_104], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d0a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d0a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d0a
.L_lambda_simple_env_end_6d0a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d0a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d0a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d0a
.L_lambda_simple_params_end_6d0a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d0a
	jmp .L_lambda_simple_end_6d0a
.L_lambda_simple_code_6d0a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d0a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d0a:
	enter 0, 0
	mov rax, PARAM(0)	; param q
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0771
	; preparing a tail-call
	mov rax, PARAM(0)	; param q
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ec7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ec7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ec7
.L_tc_recycle_frame_done_8ec7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_0771:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d0a:	; new closure is in rax
	mov qword [free_var_105], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d0b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d0b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d0b
.L_lambda_simple_env_end_6d0b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d0b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d0b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d0b
.L_lambda_simple_params_end_6d0b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d0b
	jmp .L_lambda_simple_end_6d0b
.L_lambda_simple_code_6d0b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d0b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d0b:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d0c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d0c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d0c
.L_lambda_simple_env_end_6d0c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d0c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d0c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d0c
.L_lambda_simple_params_end_6d0c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d0c
	jmp .L_lambda_simple_end_6d0c
.L_lambda_simple_code_6d0c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d0c
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d0c:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76c2
	mov rax, PARAM(0)	; param a

	jmp .L_if_end_76c2

	.L_if_else_76c2:
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ec8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ec8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ec8
.L_tc_recycle_frame_done_8ec8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76c2:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d0c:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f52:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0f52
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f52
.L_lambda_opt_env_end_0f52:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f52:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f52
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f52
.L_lambda_opt_params_end_0f52:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f52
	jmp .L_lambda_opt_end_0f52
.L_lambda_opt_code_0f52:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f52 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f52 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f52:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f52:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f52
	.L_lambda_opt_exact_shifting_loop_end_0f52:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f52
	.L_lambda_opt_arity_check_more_0f52:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f52
	.L_lambda_opt_stack_shrink_loop_0f52:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f52:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f52
	.L_lambda_opt_more_shifting_loop_end_0f52:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0f52
	.L_lambda_opt_stack_shrink_loop_exit_0f52:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f52:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ec9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ec9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ec9
.L_tc_recycle_frame_done_8ec9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0f52:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d0b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_106], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d0d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d0d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d0d
.L_lambda_simple_env_end_6d0d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d0d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d0d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d0d
.L_lambda_simple_params_end_6d0d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d0d
	jmp .L_lambda_simple_end_6d0d
.L_lambda_simple_code_6d0d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d0d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d0d:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d0e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d0e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d0e
.L_lambda_simple_env_end_6d0e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d0e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d0e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d0e
.L_lambda_simple_params_end_6d0e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d0e
	jmp .L_lambda_simple_end_6d0e
.L_lambda_simple_code_6d0e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d0e
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d0e:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76c3
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eca:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eca
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eca
.L_tc_recycle_frame_done_8eca:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76c3

	.L_if_else_76c3:
	mov rax, PARAM(0)	; param a

	.L_if_end_76c3:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d0e:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f53:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0f53
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f53
.L_lambda_opt_env_end_0f53:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f53:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f53
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f53
.L_lambda_opt_params_end_0f53:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f53
	jmp .L_lambda_opt_end_0f53
.L_lambda_opt_code_0f53:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f53 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f53 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f53:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f53:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f53
	.L_lambda_opt_exact_shifting_loop_end_0f53:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f53
	.L_lambda_opt_arity_check_more_0f53:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f53
	.L_lambda_opt_stack_shrink_loop_0f53:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f53:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f53
	.L_lambda_opt_more_shifting_loop_end_0f53:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0f53
	.L_lambda_opt_stack_shrink_loop_exit_0f53:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f53:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_29]	; free var __bin-apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ecb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ecb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ecb
.L_tc_recycle_frame_done_8ecb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0f53:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d0d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_107], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f54:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_0f54
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f54
.L_lambda_opt_env_end_0f54:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f54:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_0f54
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f54
.L_lambda_opt_params_end_0f54:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f54
	jmp .L_lambda_opt_end_0f54
.L_lambda_opt_code_0f54:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f54 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f54 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f54:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f54:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f54
	.L_lambda_opt_exact_shifting_loop_end_0f54:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f54
	.L_lambda_opt_arity_check_more_0f54:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f54
	.L_lambda_opt_stack_shrink_loop_0f54:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f54:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f54
	.L_lambda_opt_more_shifting_loop_end_0f54:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0f54
	.L_lambda_opt_stack_shrink_loop_exit_0f54:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f54:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d0f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d0f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d0f
.L_lambda_simple_env_end_6d0f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d0f:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d0f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d0f
.L_lambda_simple_params_end_6d0f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d0f
	jmp .L_lambda_simple_end_6d0f
.L_lambda_simple_code_6d0f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d0f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d0f:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param loop
	mov [rax], rbx	; box loop
	mov PARAM(0), rax	;replace param loop with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d10:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d10
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d10
.L_lambda_simple_env_end_6d10:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d10:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d10
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d10
.L_lambda_simple_params_end_6d10:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d10
	jmp .L_lambda_simple_end_6d10
.L_lambda_simple_code_6d10:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d10
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d10:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76c4
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0772
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ecc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ecc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ecc
.L_tc_recycle_frame_done_8ecc:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_0772:

	jmp .L_if_end_76c4

	.L_if_else_76c4:
	mov rax, L_constants + 2

	.L_if_end_76c4:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d10:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param loop

	pop qword[rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ecd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ecd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ecd
.L_tc_recycle_frame_done_8ecd:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d0f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ece:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ece
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ece
.L_tc_recycle_frame_done_8ece:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0f54:	; new closure is in rax
	mov qword [free_var_108], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f55:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_0f55
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f55
.L_lambda_opt_env_end_0f55:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f55:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_0f55
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f55
.L_lambda_opt_params_end_0f55:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f55
	jmp .L_lambda_opt_end_0f55
.L_lambda_opt_code_0f55:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f55 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f55 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f55:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f55:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f55
	.L_lambda_opt_exact_shifting_loop_end_0f55:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f55
	.L_lambda_opt_arity_check_more_0f55:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f55
	.L_lambda_opt_stack_shrink_loop_0f55:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f55:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f55
	.L_lambda_opt_more_shifting_loop_end_0f55:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0f55
	.L_lambda_opt_stack_shrink_loop_exit_0f55:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f55:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d11:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d11
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d11
.L_lambda_simple_env_end_6d11:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d11:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d11
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d11
.L_lambda_simple_params_end_6d11:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d11
	jmp .L_lambda_simple_end_6d11
.L_lambda_simple_code_6d11:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d11
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d11:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param loop
	mov [rax], rbx	; box loop
	mov PARAM(0), rax	;replace param loop with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d12:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d12
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d12
.L_lambda_simple_env_end_6d12:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d12:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d12
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d12
.L_lambda_simple_params_end_6d12:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d12
	jmp .L_lambda_simple_end_6d12
.L_lambda_simple_code_6d12:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d12
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d12:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0773
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76c5
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ecf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ecf
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ecf
.L_tc_recycle_frame_done_8ecf:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76c5

	.L_if_else_76c5:
	mov rax, L_constants + 2

	.L_if_end_76c5:
.L_or_end_0773:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d12:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param loop

	pop qword[rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ed0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ed0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ed0
.L_tc_recycle_frame_done_8ed0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d11:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ed1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ed1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ed1
.L_tc_recycle_frame_done_8ed1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0f55:	; new closure is in rax
	mov qword [free_var_110], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1881
	push rax
	mov rax, L_constants + 1881
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d13:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d13
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d13
.L_lambda_simple_env_end_6d13:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d13:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d13
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d13
.L_lambda_simple_params_end_6d13:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d13
	jmp .L_lambda_simple_end_6d13
.L_lambda_simple_code_6d13:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d13
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d13:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param map1
	mov [rax], rbx	; box map1
	mov PARAM(0), rax	;replace param map1 with box
	mov rax, sob_void


	mov rdi, 8
	call malloc
	mov rbx, PARAM(1)	; param map-list
	mov [rax], rbx	; box map-list
	mov PARAM(1), rax	;replace param map-list with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d14:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d14
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d14
.L_lambda_simple_env_end_6d14:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d14:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d14
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d14
.L_lambda_simple_params_end_6d14:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d14
	jmp .L_lambda_simple_end_6d14
.L_lambda_simple_code_6d14:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d14
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d14:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76c6
	mov rax, L_constants + 1

	jmp .L_if_end_76c6

	.L_if_else_76c6:
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param f
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ed2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ed2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ed2
.L_tc_recycle_frame_done_8ed2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76c6:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d14:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param map1

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d15:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d15
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d15
.L_lambda_simple_env_end_6d15:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d15:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d15
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d15
.L_lambda_simple_params_end_6d15:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d15
	jmp .L_lambda_simple_end_6d15
.L_lambda_simple_code_6d15:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d15
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d15:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76c7
	mov rax, L_constants + 1

	jmp .L_if_end_76c7

	.L_if_else_76c7:
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ed3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ed3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ed3
.L_tc_recycle_frame_done_8ed3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76c7:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d15:	; new closure is in rax

	push rax
	mov rax, PARAM(1)	; param map-list

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f56:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0f56
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f56
.L_lambda_opt_env_end_0f56:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f56:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_0f56
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f56
.L_lambda_opt_params_end_0f56:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f56
	jmp .L_lambda_opt_end_0f56
.L_lambda_opt_code_0f56:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f56 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f56 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f56:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f56:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f56
	.L_lambda_opt_exact_shifting_loop_end_0f56:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f56
	.L_lambda_opt_arity_check_more_0f56:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f56
	.L_lambda_opt_stack_shrink_loop_0f56:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f56:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f56
	.L_lambda_opt_more_shifting_loop_end_0f56:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0f56
	.L_lambda_opt_stack_shrink_loop_exit_0f56:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f56:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76c8
	mov rax, L_constants + 1

	jmp .L_if_end_76c8

	.L_if_else_76c8:
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ed4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ed4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ed4
.L_tc_recycle_frame_done_8ed4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76c8:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0f56:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d13:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_109], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d16:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d16
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d16
.L_lambda_simple_env_end_6d16:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d16:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d16
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d16
.L_lambda_simple_params_end_6d16:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d16
	jmp .L_lambda_simple_end_6d16
.L_lambda_simple_code_6d16:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d16
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d16:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 1
	push rax
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d17:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d17
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d17
.L_lambda_simple_env_end_6d17:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d17:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d17
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d17
.L_lambda_simple_params_end_6d17:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d17
	jmp .L_lambda_simple_end_6d17
.L_lambda_simple_code_6d17:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d17
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d17:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param r
	push rax
	mov rax, PARAM(1)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ed5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ed5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ed5
.L_tc_recycle_frame_done_8ed5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d17:	; new closure is in rax
	push rax
	push 3	; arg count
	mov rax, qword [free_var_112]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ed6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ed6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ed6
.L_tc_recycle_frame_done_8ed6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d16:	; new closure is in rax
	mov qword [free_var_111], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1881
	push rax
	mov rax, L_constants + 1881
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d18:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d18
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d18
.L_lambda_simple_env_end_6d18:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d18:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d18
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d18
.L_lambda_simple_params_end_6d18:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d18
	jmp .L_lambda_simple_end_6d18
.L_lambda_simple_code_6d18:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d18
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d18:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run-1
	mov [rax], rbx	; box run-1
	mov PARAM(0), rax	;replace param run-1 with box
	mov rax, sob_void


	mov rdi, 8
	call malloc
	mov rbx, PARAM(1)	; param run-2
	mov [rax], rbx	; box run-2
	mov PARAM(1), rax	;replace param run-2 with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d19:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d19
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d19
.L_lambda_simple_env_end_6d19:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d19:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d19
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d19
.L_lambda_simple_params_end_6d19:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d19
	jmp .L_lambda_simple_end_6d19
.L_lambda_simple_code_6d19:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d19
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d19:
	enter 0, 0
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76c9
	mov rax, PARAM(0)	; param s1

	jmp .L_if_end_76c9

	.L_if_else_76c9:
	; preparing a tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param s1
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ed7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ed7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ed7
.L_tc_recycle_frame_done_8ed7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76c9:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d19:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run-1

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d1a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d1a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d1a
.L_lambda_simple_env_end_6d1a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d1a:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d1a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d1a
.L_lambda_simple_params_end_6d1a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d1a
	jmp .L_lambda_simple_end_6d1a
.L_lambda_simple_code_6d1a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d1a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d1a:
	enter 0, 0
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76ca
	mov rax, PARAM(1)	; param s2

	jmp .L_if_end_76ca

	.L_if_else_76ca:
	; preparing a tail-call
	mov rax, PARAM(1)	; param s2
	push rax
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ed8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ed8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ed8
.L_tc_recycle_frame_done_8ed8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76ca:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d1a:	; new closure is in rax

	push rax
	mov rax, PARAM(1)	; param run-2

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f57:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0f57
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f57
.L_lambda_opt_env_end_0f57:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f57:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_0f57
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f57
.L_lambda_opt_params_end_0f57:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f57
	jmp .L_lambda_opt_end_0f57
.L_lambda_opt_code_0f57:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f57 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f57 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f57:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f57:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f57
	.L_lambda_opt_exact_shifting_loop_end_0f57:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f57
	.L_lambda_opt_arity_check_more_0f57:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f57
	.L_lambda_opt_stack_shrink_loop_0f57:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f57:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f57
	.L_lambda_opt_more_shifting_loop_end_0f57:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_0f57
	.L_lambda_opt_stack_shrink_loop_exit_0f57:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f57:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76cb
	mov rax, L_constants + 1

	jmp .L_if_end_76cb

	.L_if_else_76cb:
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ed9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ed9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ed9
.L_tc_recycle_frame_done_8ed9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76cb:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0f57:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d18:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_113], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d1b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d1b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d1b
.L_lambda_simple_env_end_6d1b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d1b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d1b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d1b
.L_lambda_simple_params_end_6d1b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d1b
	jmp .L_lambda_simple_end_6d1b
.L_lambda_simple_code_6d1b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d1b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d1b:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d1c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d1c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d1c
.L_lambda_simple_env_end_6d1c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d1c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d1c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d1c
.L_lambda_simple_params_end_6d1c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d1c
	jmp .L_lambda_simple_end_6d1c
.L_lambda_simple_code_6d1c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_6d1c
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d1c:
	enter 0, 0
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_108]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76cc
	mov rax, PARAM(1)	; param unit

	jmp .L_if_end_76cc

	.L_if_else_76cc:
	; preparing a tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eda:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eda
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eda
.L_tc_recycle_frame_done_8eda:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76cc:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_6d1c:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f58:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0f58
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f58
.L_lambda_opt_env_end_0f58:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f58:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f58
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f58
.L_lambda_opt_params_end_0f58:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f58
	jmp .L_lambda_opt_end_0f58
.L_lambda_opt_code_0f58:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f58 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f58 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 2
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f58:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f58:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f58
	.L_lambda_opt_exact_shifting_loop_end_0f58:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f58
	.L_lambda_opt_arity_check_more_0f58:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 3;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f58
	.L_lambda_opt_stack_shrink_loop_0f58:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f58:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f58
	.L_lambda_opt_more_shifting_loop_end_0f58:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 3
	jg .L_lambda_opt_stack_shrink_loop_0f58
	.L_lambda_opt_stack_shrink_loop_exit_0f58:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f58:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8edb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8edb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8edb
.L_tc_recycle_frame_done_8edb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_0f58:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d1b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_112], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d1d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d1d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d1d
.L_lambda_simple_env_end_6d1d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d1d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d1d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d1d
.L_lambda_simple_params_end_6d1d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d1d
	jmp .L_lambda_simple_end_6d1d
.L_lambda_simple_code_6d1d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d1d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d1d:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d1e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d1e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d1e
.L_lambda_simple_env_end_6d1e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d1e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d1e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d1e
.L_lambda_simple_params_end_6d1e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d1e
	jmp .L_lambda_simple_end_6d1e
.L_lambda_simple_code_6d1e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_6d1e
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d1e:
	enter 0, 0
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_108]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76cd
	mov rax, PARAM(1)	; param unit

	jmp .L_if_end_76cd

	.L_if_else_76cd:
	; preparing a tail-call
	mov rax, L_constants + 1
	push rax
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_113]	; free var append
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8edc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8edc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8edc
.L_tc_recycle_frame_done_8edc:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76cd:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_6d1e:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f59:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0f59
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f59
.L_lambda_opt_env_end_0f59:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f59:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f59
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f59
.L_lambda_opt_params_end_0f59:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f59
	jmp .L_lambda_opt_end_0f59
.L_lambda_opt_code_0f59:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f59 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f59 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 2
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f59:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f59:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f59
	.L_lambda_opt_exact_shifting_loop_end_0f59:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f59
	.L_lambda_opt_arity_check_more_0f59:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 3;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f59
	.L_lambda_opt_stack_shrink_loop_0f59:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f59:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f59
	.L_lambda_opt_more_shifting_loop_end_0f59:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 3
	jg .L_lambda_opt_stack_shrink_loop_0f59
	.L_lambda_opt_stack_shrink_loop_exit_0f59:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f59:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8edd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8edd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8edd
.L_tc_recycle_frame_done_8edd:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_0f59:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d1d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_114], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d1f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d1f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d1f
.L_lambda_simple_env_end_6d1f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d1f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d1f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d1f
.L_lambda_simple_params_end_6d1f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d1f
	jmp .L_lambda_simple_end_6d1f
.L_lambda_simple_code_6d1f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_6d1f
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d1f:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2075
	push rax
	mov rax, L_constants + 2066
	push rax
	push 2	; arg count
	mov rax, qword [free_var_42]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ede:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ede
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ede
.L_tc_recycle_frame_done_8ede:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_6d1f:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d20:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d20
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d20
.L_lambda_simple_env_end_6d20:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d20:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d20
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d20
.L_lambda_simple_params_end_6d20:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d20
	jmp .L_lambda_simple_end_6d20
.L_lambda_simple_code_6d20:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d20
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d20:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d21:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d21
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d21
.L_lambda_simple_env_end_6d21:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d21:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d21
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d21
.L_lambda_simple_params_end_6d21:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d21
	jmp .L_lambda_simple_end_6d21
.L_lambda_simple_code_6d21:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d21
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d21:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76ce
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76cf
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_38]	; free var __bin-add-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8edf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8edf
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8edf
.L_tc_recycle_frame_done_8edf:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76cf

	.L_if_else_76cf:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76d0
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_34]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ee0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ee0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ee0
.L_tc_recycle_frame_done_8ee0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76d0

	.L_if_else_76d0:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76d1
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_30]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ee1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ee1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ee1
.L_tc_recycle_frame_done_8ee1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76d1

	.L_if_else_76d1:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ee2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ee2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ee2
.L_tc_recycle_frame_done_8ee2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76d1:

	.L_if_end_76d0:

	.L_if_end_76cf:

	jmp .L_if_end_76ce

	.L_if_else_76ce:
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76d2
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76d3
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var __bin_integer_to_fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_34]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ee3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ee3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ee3
.L_tc_recycle_frame_done_8ee3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76d3

	.L_if_else_76d3:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76d4
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_34]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ee4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ee4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ee4
.L_tc_recycle_frame_done_8ee4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76d4

	.L_if_else_76d4:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76d5
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_30]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ee5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ee5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ee5
.L_tc_recycle_frame_done_8ee5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76d5

	.L_if_else_76d5:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ee6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ee6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ee6
.L_tc_recycle_frame_done_8ee6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76d5:

	.L_if_end_76d4:

	.L_if_end_76d3:

	jmp .L_if_end_76d2

	.L_if_else_76d2:
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76d6
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76d7
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_30]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ee7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ee7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ee7
.L_tc_recycle_frame_done_8ee7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76d7

	.L_if_else_76d7:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76d8
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_30]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ee8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ee8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ee8
.L_tc_recycle_frame_done_8ee8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76d8

	.L_if_else_76d8:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76d9
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_30]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ee9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ee9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ee9
.L_tc_recycle_frame_done_8ee9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76d9

	.L_if_else_76d9:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eea:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eea
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eea
.L_tc_recycle_frame_done_8eea:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76d9:

	.L_if_end_76d8:

	.L_if_end_76d7:

	jmp .L_if_end_76d6

	.L_if_else_76d6:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eeb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eeb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eeb
.L_tc_recycle_frame_done_8eeb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76d6:

	.L_if_end_76d2:

	.L_if_end_76ce:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d21:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d22:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d22
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d22
.L_lambda_simple_env_end_6d22:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d22:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d22
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d22
.L_lambda_simple_params_end_6d22:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d22
	jmp .L_lambda_simple_end_6d22
.L_lambda_simple_code_6d22:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d22
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d22:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f5a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_0f5a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f5a
.L_lambda_opt_env_end_0f5a:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f5a:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f5a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f5a
.L_lambda_opt_params_end_0f5a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f5a
	jmp .L_lambda_opt_end_0f5a
.L_lambda_opt_code_0f5a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f5a ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f5a ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f5a:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f5a:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f5a
	.L_lambda_opt_exact_shifting_loop_end_0f5a:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f5a
	.L_lambda_opt_arity_check_more_0f5a:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f5a
	.L_lambda_opt_stack_shrink_loop_0f5a:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f5a:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f5a
	.L_lambda_opt_more_shifting_loop_end_0f5a:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_0f5a
	.L_lambda_opt_stack_shrink_loop_exit_0f5a:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f5a:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2023
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin+
	push rax
	push 3	; arg count
	mov rax, qword [free_var_112]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eec:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eec
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eec
.L_tc_recycle_frame_done_8eec:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0f5a:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d22:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eed:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eed
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eed
.L_tc_recycle_frame_done_8eed:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d20:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_115], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d23:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d23
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d23
.L_lambda_simple_env_end_6d23:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d23:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d23
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d23
.L_lambda_simple_params_end_6d23:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d23
	jmp .L_lambda_simple_end_6d23
.L_lambda_simple_code_6d23:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_6d23
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d23:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2075
	push rax
	mov rax, L_constants + 2139
	push rax
	push 2	; arg count
	mov rax, qword [free_var_42]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eee:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eee
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eee
.L_tc_recycle_frame_done_8eee:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_6d23:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d24:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d24
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d24
.L_lambda_simple_env_end_6d24:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d24:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d24
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d24
.L_lambda_simple_params_end_6d24:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d24
	jmp .L_lambda_simple_end_6d24
.L_lambda_simple_code_6d24:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d24
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d24:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d25:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d25
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d25
.L_lambda_simple_env_end_6d25:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d25:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d25
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d25
.L_lambda_simple_params_end_6d25:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d25
	jmp .L_lambda_simple_end_6d25
.L_lambda_simple_code_6d25:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d25
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d25:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76da
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76db
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_39]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eef:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eef
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eef
.L_tc_recycle_frame_done_8eef:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76db

	.L_if_else_76db:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76dc
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_35]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ef0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ef0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ef0
.L_tc_recycle_frame_done_8ef0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76dc

	.L_if_else_76dc:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_118]	; free var real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76dd
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_31]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ef1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ef1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ef1
.L_tc_recycle_frame_done_8ef1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76dd

	.L_if_else_76dd:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ef2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ef2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ef2
.L_tc_recycle_frame_done_8ef2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76dd:

	.L_if_end_76dc:

	.L_if_end_76db:

	jmp .L_if_end_76da

	.L_if_else_76da:
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76de
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76df
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_35]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ef3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ef3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ef3
.L_tc_recycle_frame_done_8ef3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76df

	.L_if_else_76df:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76e0
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_35]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ef4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ef4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ef4
.L_tc_recycle_frame_done_8ef4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76e0

	.L_if_else_76e0:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76e1
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_31]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ef5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ef5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ef5
.L_tc_recycle_frame_done_8ef5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76e1

	.L_if_else_76e1:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ef6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ef6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ef6
.L_tc_recycle_frame_done_8ef6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76e1:

	.L_if_end_76e0:

	.L_if_end_76df:

	jmp .L_if_end_76de

	.L_if_else_76de:
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76e2
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76e3
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_31]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ef7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ef7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ef7
.L_tc_recycle_frame_done_8ef7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76e3

	.L_if_else_76e3:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76e4
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_31]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ef8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ef8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ef8
.L_tc_recycle_frame_done_8ef8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76e4

	.L_if_else_76e4:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76e5
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_31]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8ef9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8ef9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8ef9
.L_tc_recycle_frame_done_8ef9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76e5

	.L_if_else_76e5:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8efa:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8efa
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8efa
.L_tc_recycle_frame_done_8efa:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76e5:

	.L_if_end_76e4:

	.L_if_end_76e3:

	jmp .L_if_end_76e2

	.L_if_else_76e2:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8efb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8efb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8efb
.L_tc_recycle_frame_done_8efb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76e2:

	.L_if_end_76de:

	.L_if_end_76da:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d25:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d26:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d26
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d26
.L_lambda_simple_env_end_6d26:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d26:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d26
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d26
.L_lambda_simple_params_end_6d26:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d26
	jmp .L_lambda_simple_end_6d26
.L_lambda_simple_code_6d26:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d26
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d26:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f5b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_0f5b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f5b
.L_lambda_opt_env_end_0f5b:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f5b:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f5b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f5b
.L_lambda_opt_params_end_0f5b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f5b
	jmp .L_lambda_opt_end_0f5b
.L_lambda_opt_code_0f5b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f5b ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f5b ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f5b:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f5b:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f5b
	.L_lambda_opt_exact_shifting_loop_end_0f5b:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f5b
	.L_lambda_opt_arity_check_more_0f5b:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f5b
	.L_lambda_opt_stack_shrink_loop_0f5b:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f5b:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f5b
	.L_lambda_opt_more_shifting_loop_end_0f5b:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0f5b
	.L_lambda_opt_stack_shrink_loop_exit_0f5b:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f5b:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76e6
	; preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, L_constants + 2023
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin-
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8efc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8efc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8efc
.L_tc_recycle_frame_done_8efc:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76e6

	.L_if_else_76e6:
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, L_constants + 2023
	push rax
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, qword [free_var_112]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d27:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_6d27
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d27
.L_lambda_simple_env_end_6d27:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d27:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d27
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d27
.L_lambda_simple_params_end_6d27:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d27
	jmp .L_lambda_simple_end_6d27
.L_lambda_simple_code_6d27:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d27
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d27:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8efd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8efd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8efd
.L_tc_recycle_frame_done_8efd:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d27:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8efe:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8efe
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8efe
.L_tc_recycle_frame_done_8efe:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76e6:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0f5b:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d26:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8eff:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8eff
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8eff
.L_tc_recycle_frame_done_8eff:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d24:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_117], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d28:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d28
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d28
.L_lambda_simple_env_end_6d28:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d28:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d28
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d28
.L_lambda_simple_params_end_6d28:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d28
	jmp .L_lambda_simple_end_6d28
.L_lambda_simple_code_6d28:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_6d28
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d28:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2075
	push rax
	mov rax, L_constants + 2167
	push rax
	push 2	; arg count
	mov rax, qword [free_var_42]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f00:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f00
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f00
.L_tc_recycle_frame_done_8f00:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_6d28:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d29:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d29
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d29
.L_lambda_simple_env_end_6d29:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d29:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d29
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d29
.L_lambda_simple_params_end_6d29:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d29
	jmp .L_lambda_simple_end_6d29
.L_lambda_simple_code_6d29:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d29
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d29:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d2a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d2a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d2a
.L_lambda_simple_env_end_6d2a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d2a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d2a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d2a
.L_lambda_simple_params_end_6d2a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d2a
	jmp .L_lambda_simple_end_6d2a
.L_lambda_simple_code_6d2a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d2a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d2a:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76e7
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76e8
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_40]	; free var __bin-mul-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f01:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f01
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f01
.L_tc_recycle_frame_done_8f01:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76e8

	.L_if_else_76e8:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76e9
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_36]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f02:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f02
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f02
.L_tc_recycle_frame_done_8f02:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76e9

	.L_if_else_76e9:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76ea
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_32]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f03:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f03
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f03
.L_tc_recycle_frame_done_8f03:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76ea

	.L_if_else_76ea:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f04:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f04
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f04
.L_tc_recycle_frame_done_8f04:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76ea:

	.L_if_end_76e9:

	.L_if_end_76e8:

	jmp .L_if_end_76e7

	.L_if_else_76e7:
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76eb
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76ec
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_36]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f05:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f05
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f05
.L_tc_recycle_frame_done_8f05:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76ec

	.L_if_else_76ec:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76ed
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_36]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f06:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f06
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f06
.L_tc_recycle_frame_done_8f06:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76ed

	.L_if_else_76ed:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76ee
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_32]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f07:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f07
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f07
.L_tc_recycle_frame_done_8f07:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76ee

	.L_if_else_76ee:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f08:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f08
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f08
.L_tc_recycle_frame_done_8f08:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76ee:

	.L_if_end_76ed:

	.L_if_end_76ec:

	jmp .L_if_end_76eb

	.L_if_else_76eb:
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76ef
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76f0
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_32]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f09:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f09
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f09
.L_tc_recycle_frame_done_8f09:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76f0

	.L_if_else_76f0:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76f1
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_32]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f0a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f0a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f0a
.L_tc_recycle_frame_done_8f0a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76f1

	.L_if_else_76f1:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76f2
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_32]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f0b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f0b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f0b
.L_tc_recycle_frame_done_8f0b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76f2

	.L_if_else_76f2:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f0c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f0c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f0c
.L_tc_recycle_frame_done_8f0c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76f2:

	.L_if_end_76f1:

	.L_if_end_76f0:

	jmp .L_if_end_76ef

	.L_if_else_76ef:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f0d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f0d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f0d
.L_tc_recycle_frame_done_8f0d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76ef:

	.L_if_end_76eb:

	.L_if_end_76e7:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d2a:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d2b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d2b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d2b
.L_lambda_simple_env_end_6d2b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d2b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d2b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d2b
.L_lambda_simple_params_end_6d2b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d2b
	jmp .L_lambda_simple_end_6d2b
.L_lambda_simple_code_6d2b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d2b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d2b:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f5c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_0f5c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f5c
.L_lambda_opt_env_end_0f5c:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f5c:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f5c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f5c
.L_lambda_opt_params_end_0f5c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f5c
	jmp .L_lambda_opt_end_0f5c
.L_lambda_opt_code_0f5c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f5c ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f5c ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f5c:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f5c:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f5c
	.L_lambda_opt_exact_shifting_loop_end_0f5c:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f5c
	.L_lambda_opt_arity_check_more_0f5c:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f5c
	.L_lambda_opt_stack_shrink_loop_0f5c:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f5c:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f5c
	.L_lambda_opt_more_shifting_loop_end_0f5c:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_0f5c
	.L_lambda_opt_stack_shrink_loop_exit_0f5c:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f5c:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2158
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin*
	push rax
	push 3	; arg count
	mov rax, qword [free_var_112]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f0e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f0e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f0e
.L_tc_recycle_frame_done_8f0e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0f5c:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d2b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f0f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f0f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f0f
.L_tc_recycle_frame_done_8f0f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d29:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_119], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d2c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d2c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d2c
.L_lambda_simple_env_end_6d2c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d2c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d2c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d2c
.L_lambda_simple_params_end_6d2c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d2c
	jmp .L_lambda_simple_end_6d2c
.L_lambda_simple_code_6d2c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_6d2c
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d2c:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2075
	push rax
	mov rax, L_constants + 2186
	push rax
	push 2	; arg count
	mov rax, qword [free_var_42]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f10:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f10
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f10
.L_tc_recycle_frame_done_8f10:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_6d2c:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d2d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d2d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d2d
.L_lambda_simple_env_end_6d2d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d2d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d2d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d2d
.L_lambda_simple_params_end_6d2d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d2d
	jmp .L_lambda_simple_end_6d2d
.L_lambda_simple_code_6d2d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d2d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d2d:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d2e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d2e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d2e
.L_lambda_simple_env_end_6d2e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d2e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d2e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d2e
.L_lambda_simple_params_end_6d2e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d2e
	jmp .L_lambda_simple_end_6d2e
.L_lambda_simple_code_6d2e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d2e
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d2e:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76f3
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76f4
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_41]	; free var __bin-div-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f11:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f11
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f11
.L_tc_recycle_frame_done_8f11:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76f4

	.L_if_else_76f4:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76f5
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_37]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f12:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f12
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f12
.L_tc_recycle_frame_done_8f12:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76f5

	.L_if_else_76f5:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76f6
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f13:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f13
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f13
.L_tc_recycle_frame_done_8f13:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76f6

	.L_if_else_76f6:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f14:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f14
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f14
.L_tc_recycle_frame_done_8f14:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76f6:

	.L_if_end_76f5:

	.L_if_end_76f4:

	jmp .L_if_end_76f3

	.L_if_else_76f3:
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76f7
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76f8
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_37]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f15:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f15
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f15
.L_tc_recycle_frame_done_8f15:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76f8

	.L_if_else_76f8:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76f9
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_37]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f16:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f16
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f16
.L_tc_recycle_frame_done_8f16:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76f9

	.L_if_else_76f9:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76fa
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f17:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f17
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f17
.L_tc_recycle_frame_done_8f17:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76fa

	.L_if_else_76fa:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f18:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f18
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f18
.L_tc_recycle_frame_done_8f18:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76fa:

	.L_if_end_76f9:

	.L_if_end_76f8:

	jmp .L_if_end_76f7

	.L_if_else_76f7:
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76fb
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76fc
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f19:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f19
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f19
.L_tc_recycle_frame_done_8f19:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76fc

	.L_if_else_76fc:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76fd
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f1a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f1a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f1a
.L_tc_recycle_frame_done_8f1a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76fd

	.L_if_else_76fd:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76fe
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f1b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f1b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f1b
.L_tc_recycle_frame_done_8f1b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76fe

	.L_if_else_76fe:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f1c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f1c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f1c
.L_tc_recycle_frame_done_8f1c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76fe:

	.L_if_end_76fd:

	.L_if_end_76fc:

	jmp .L_if_end_76fb

	.L_if_else_76fb:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f1d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f1d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f1d
.L_tc_recycle_frame_done_8f1d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76fb:

	.L_if_end_76f7:

	.L_if_end_76f3:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d2e:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d2f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d2f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d2f
.L_lambda_simple_env_end_6d2f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d2f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d2f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d2f
.L_lambda_simple_params_end_6d2f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d2f
	jmp .L_lambda_simple_end_6d2f
.L_lambda_simple_code_6d2f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d2f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d2f:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f5d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_0f5d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f5d
.L_lambda_opt_env_end_0f5d:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f5d:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f5d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f5d
.L_lambda_opt_params_end_0f5d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f5d
	jmp .L_lambda_opt_end_0f5d
.L_lambda_opt_code_0f5d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f5d ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f5d ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f5d:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f5d:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f5d
	.L_lambda_opt_exact_shifting_loop_end_0f5d:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f5d
	.L_lambda_opt_arity_check_more_0f5d:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f5d
	.L_lambda_opt_stack_shrink_loop_0f5d:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f5d:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f5d
	.L_lambda_opt_more_shifting_loop_end_0f5d:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0f5d
	.L_lambda_opt_stack_shrink_loop_exit_0f5d:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f5d:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_76ff
	; preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, L_constants + 2158
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin/
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f1e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f1e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f1e
.L_tc_recycle_frame_done_8f1e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_76ff

	.L_if_else_76ff:
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, L_constants + 2158
	push rax
	mov rax, qword [free_var_119]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, qword [free_var_112]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d30:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_6d30
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d30
.L_lambda_simple_env_end_6d30:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d30:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d30
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d30
.L_lambda_simple_params_end_6d30:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d30
	jmp .L_lambda_simple_end_6d30
.L_lambda_simple_code_6d30:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d30
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d30:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin/
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f1f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f1f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f1f
.L_tc_recycle_frame_done_8f1f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d30:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f20:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f20
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f20
.L_tc_recycle_frame_done_8f20:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_76ff:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0f5d:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d2f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f21:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f21
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f21
.L_tc_recycle_frame_done_8f21:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d2d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_120], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d31:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d31
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d31
.L_lambda_simple_env_end_6d31:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d31:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d31
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d31
.L_lambda_simple_params_end_6d31:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d31
	jmp .L_lambda_simple_end_6d31
.L_lambda_simple_code_6d31:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d31
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d31:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_27]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7700
	mov rax, L_constants + 2158

	jmp .L_if_end_7700

	.L_if_else_7700:
	; preparing a tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_121]	; free var fact
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_119]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f22:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f22
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f22
.L_tc_recycle_frame_done_8f22:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_7700:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d31:	; new closure is in rax
	mov qword [free_var_121], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_122], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_123], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_124], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_125], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_126], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d32:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d32
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d32
.L_lambda_simple_env_end_6d32:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d32:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d32
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d32
.L_lambda_simple_params_end_6d32:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d32
	jmp .L_lambda_simple_end_6d32
.L_lambda_simple_code_6d32:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_6d32
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d32:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2296
	push rax
	mov rax, L_constants + 2287
	push rax
	push 2	; arg count
	mov rax, qword [free_var_42]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f23:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f23
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f23
.L_tc_recycle_frame_done_8f23:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_6d32:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d33:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d33
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d33
.L_lambda_simple_env_end_6d33:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d33:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d33
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d33
.L_lambda_simple_params_end_6d33:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d33
	jmp .L_lambda_simple_end_6d33
.L_lambda_simple_code_6d33:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d33
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d33:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d34:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d34
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d34
.L_lambda_simple_env_end_6d34:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d34:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d34
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d34
.L_lambda_simple_params_end_6d34:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d34
	jmp .L_lambda_simple_end_6d34
.L_lambda_simple_code_6d34:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_6d34
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d34:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d35:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d35
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d35
.L_lambda_simple_env_end_6d35:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d35:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_6d35
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d35
.L_lambda_simple_params_end_6d35:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d35
	jmp .L_lambda_simple_end_6d35
.L_lambda_simple_code_6d35:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d35
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d35:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7701
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7702
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator-zz
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f24:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f24
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f24
.L_tc_recycle_frame_done_8f24:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7702

	.L_if_else_7702:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7703
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f25:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f25
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f25
.L_tc_recycle_frame_done_8f25:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7703

	.L_if_else_7703:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7704
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f26:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f26
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f26
.L_tc_recycle_frame_done_8f26:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7704

	.L_if_else_7704:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f27:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f27
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f27
.L_tc_recycle_frame_done_8f27:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_7704:

	.L_if_end_7703:

	.L_if_end_7702:

	jmp .L_if_end_7701

	.L_if_else_7701:
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7705
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7706
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f28:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f28
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f28
.L_tc_recycle_frame_done_8f28:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7706

	.L_if_else_7706:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7707
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f29:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f29
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f29
.L_tc_recycle_frame_done_8f29:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7707

	.L_if_else_7707:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7708
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f2a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f2a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f2a
.L_tc_recycle_frame_done_8f2a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7708

	.L_if_else_7708:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f2b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f2b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f2b
.L_tc_recycle_frame_done_8f2b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_7708:

	.L_if_end_7707:

	.L_if_end_7706:

	jmp .L_if_end_7705

	.L_if_else_7705:
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7709
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_770a
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f2c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f2c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f2c
.L_tc_recycle_frame_done_8f2c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_770a

	.L_if_else_770a:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_770b
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f2d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f2d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f2d
.L_tc_recycle_frame_done_8f2d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_770b

	.L_if_else_770b:
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_770c
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f2e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f2e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f2e
.L_tc_recycle_frame_done_8f2e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_770c

	.L_if_else_770c:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f2f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f2f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f2f
.L_tc_recycle_frame_done_8f2f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_770c:

	.L_if_end_770b:

	.L_if_end_770a:

	jmp .L_if_end_7709

	.L_if_else_7709:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f30:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f30
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f30
.L_tc_recycle_frame_done_8f30:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_7709:

	.L_if_end_7705:

	.L_if_end_7701:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d35:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_6d34:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d36:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d36
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d36
.L_lambda_simple_env_end_6d36:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d36:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d36
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d36
.L_lambda_simple_params_end_6d36:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d36
	jmp .L_lambda_simple_end_6d36
.L_lambda_simple_code_6d36:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d36
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d36:
	enter 0, 0
	; preparing a tail-call
	mov rax, qword [free_var_43]	; free var __bin-less-than-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_44]	; free var __bin-less-than-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_45]	; free var __bin-less-than-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, PARAM(0)	; param make-bin-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d37:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d37
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d37
.L_lambda_simple_env_end_6d37:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d37:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d37
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d37
.L_lambda_simple_params_end_6d37:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d37
	jmp .L_lambda_simple_end_6d37
.L_lambda_simple_code_6d37:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d37
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d37:
	enter 0, 0
	; preparing a tail-call
	mov rax, qword [free_var_46]	; free var __bin-equal-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_47]	; free var __bin-equal-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_48]	; free var __bin-equal-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var make-bin-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d38:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_6d38
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d38
.L_lambda_simple_env_end_6d38:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d38:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d38
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d38
.L_lambda_simple_params_end_6d38:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d38
	jmp .L_lambda_simple_end_6d38
.L_lambda_simple_code_6d38:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d38
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d38:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d39:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_6d39
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d39
.L_lambda_simple_env_end_6d39:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d39:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d39
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d39
.L_lambda_simple_params_end_6d39:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d39
	jmp .L_lambda_simple_end_6d39
.L_lambda_simple_code_6d39:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d39
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d39:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_104]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f31:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f31
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f31
.L_tc_recycle_frame_done_8f31:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d39:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d3a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_6d3a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d3a
.L_lambda_simple_env_end_6d3a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d3a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d3a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d3a
.L_lambda_simple_params_end_6d3a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d3a
	jmp .L_lambda_simple_end_6d3a
.L_lambda_simple_code_6d3a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d3a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d3a:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 6	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d3b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_6d3b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d3b
.L_lambda_simple_env_end_6d3b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d3b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d3b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d3b
.L_lambda_simple_params_end_6d3b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d3b
	jmp .L_lambda_simple_end_6d3b
.L_lambda_simple_code_6d3b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d3b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d3b:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f32:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f32
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f32
.L_tc_recycle_frame_done_8f32:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d3b:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 6	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d3c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_6d3c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d3c
.L_lambda_simple_env_end_6d3c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d3c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d3c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d3c
.L_lambda_simple_params_end_6d3c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d3c
	jmp .L_lambda_simple_end_6d3c
.L_lambda_simple_code_6d3c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d3c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d3c:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 7	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d3d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_6d3d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d3d
.L_lambda_simple_env_end_6d3d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d3d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d3d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d3d
.L_lambda_simple_params_end_6d3d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d3d
	jmp .L_lambda_simple_end_6d3d
.L_lambda_simple_code_6d3d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d3d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d3d:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin>?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_104]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f33:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f33
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f33
.L_tc_recycle_frame_done_8f33:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d3d:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 7	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d3e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_6d3e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d3e
.L_lambda_simple_env_end_6d3e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d3e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d3e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d3e
.L_lambda_simple_params_end_6d3e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d3e
	jmp .L_lambda_simple_end_6d3e
.L_lambda_simple_code_6d3e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d3e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d3e:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 8	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d3f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_6d3f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d3f
.L_lambda_simple_env_end_6d3f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d3f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d3f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d3f
.L_lambda_simple_params_end_6d3f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d3f
	jmp .L_lambda_simple_end_6d3f
.L_lambda_simple_code_6d3f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d3f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d3f:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 9	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d40:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_6d40
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d40
.L_lambda_simple_env_end_6d40:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d40:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d40
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d40
.L_lambda_simple_params_end_6d40:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d40
	jmp .L_lambda_simple_end_6d40
.L_lambda_simple_code_6d40:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d40
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d40:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 10	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d41:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 9
	je .L_lambda_simple_env_end_6d41
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d41
.L_lambda_simple_env_end_6d41:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d41:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d41
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d41
.L_lambda_simple_params_end_6d41:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d41
	jmp .L_lambda_simple_end_6d41
.L_lambda_simple_code_6d41:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d41
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d41:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0774
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-ordering
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_770d
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f34:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f34
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f34
.L_tc_recycle_frame_done_8f34:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_770d

	.L_if_else_770d:
	mov rax, L_constants + 2

	.L_if_end_770d:
.L_or_end_0774:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d41:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 10	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f5e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 9
	je .L_lambda_opt_env_end_0f5e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f5e
.L_lambda_opt_env_end_0f5e:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f5e:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f5e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f5e
.L_lambda_opt_params_end_0f5e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f5e
	jmp .L_lambda_opt_end_0f5e
.L_lambda_opt_code_0f5e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f5e ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f5e ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f5e:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f5e:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f5e
	.L_lambda_opt_exact_shifting_loop_end_0f5e:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f5e
	.L_lambda_opt_arity_check_more_0f5e:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f5e
	.L_lambda_opt_stack_shrink_loop_0f5e:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f5e:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f5e
	.L_lambda_opt_more_shifting_loop_end_0f5e:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0f5e
	.L_lambda_opt_stack_shrink_loop_exit_0f5e:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f5e:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f35:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f35
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f35
.L_tc_recycle_frame_done_8f35:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0f5e:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d40:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f36:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f36
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f36
.L_tc_recycle_frame_done_8f36:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d3f:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 8	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d42:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_6d42
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d42
.L_lambda_simple_env_end_6d42:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d42:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d42
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d42
.L_lambda_simple_params_end_6d42:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d42
	jmp .L_lambda_simple_end_6d42
.L_lambda_simple_code_6d42:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d42
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d42:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 4]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_122], rax	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin<=?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_123], rax	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin>?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_124], rax	; free var >
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var bin>=?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_125], rax	; free var >=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 3]
	mov rax, qword [rax + 8 * 0]	; bound var bin=?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_126], rax	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d42:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f37:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f37
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f37
.L_tc_recycle_frame_done_8f37:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d3e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f38:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f38
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f38
.L_tc_recycle_frame_done_8f38:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d3c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f39:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f39
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f39
.L_tc_recycle_frame_done_8f39:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d3a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f3a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f3a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f3a
.L_tc_recycle_frame_done_8f3a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d38:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f3b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f3b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f3b
.L_tc_recycle_frame_done_8f3b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d37:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f3c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f3c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f3c
.L_tc_recycle_frame_done_8f3c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d36:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f3d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f3d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f3d
.L_tc_recycle_frame_done_8f3d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d33:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d43:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d43
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d43
.L_lambda_simple_env_end_6d43:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d43:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d43
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d43
.L_lambda_simple_params_end_6d43:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d43
	jmp .L_lambda_simple_end_6d43
.L_lambda_simple_code_6d43:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d43
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d43:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d44:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d44
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d44
.L_lambda_simple_env_end_6d44:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d44:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d44
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d44
.L_lambda_simple_params_end_6d44:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d44
	jmp .L_lambda_simple_end_6d44
.L_lambda_simple_code_6d44:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d44
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d44:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_27]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_770e
	mov rax, L_constants + 1

	jmp .L_if_end_770e

	.L_if_else_770e:
	; preparing a tail-call
	mov rax, PARAM(1)	; param ch
	push rax
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param ch
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f3e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f3e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f3e
.L_tc_recycle_frame_done_8f3e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_770e:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d44:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f5f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0f5f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f5f
.L_lambda_opt_env_end_0f5f:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f5f:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f5f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f5f
.L_lambda_opt_params_end_0f5f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f5f
	jmp .L_lambda_opt_end_0f5f
.L_lambda_opt_code_0f5f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f5f ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f5f ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f5f:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f5f:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f5f
	.L_lambda_opt_exact_shifting_loop_end_0f5f:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f5f
	.L_lambda_opt_arity_check_more_0f5f:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f5f
	.L_lambda_opt_stack_shrink_loop_0f5f:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f5f:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f5f
	.L_lambda_opt_more_shifting_loop_end_0f5f:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0f5f
	.L_lambda_opt_stack_shrink_loop_exit_0f5f:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f5f:
	enter 0, 0
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_770f
	; preparing a tail-call
	mov rax, L_constants + 4
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f3f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f3f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f3f
.L_tc_recycle_frame_done_8f3f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_770f

	.L_if_else_770f:
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7711
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7711

	.L_if_else_7711:
	mov rax, L_constants + 2

	.L_if_end_7711:

	cmp rax, sob_boolean_false
	je .L_if_else_7710
	; preparing a tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f40:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f40
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f40
.L_tc_recycle_frame_done_8f40:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7710

	.L_if_else_7710:
	; preparing a tail-call
	mov rax, L_constants + 2365
	push rax
	mov rax, L_constants + 2356
	push rax
	push 2	; arg count
	mov rax, qword [free_var_42]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f41:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f41
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f41
.L_tc_recycle_frame_done_8f41:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_7710:

	.L_if_end_770f:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0f5f:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d43:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_127], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_128], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_129], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_130], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_131], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_132], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d45:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d45
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d45
.L_lambda_simple_env_end_6d45:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d45:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d45
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d45
.L_lambda_simple_params_end_6d45:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d45
	jmp .L_lambda_simple_end_6d45
.L_lambda_simple_code_6d45:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d45
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d45:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f60:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0f60
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f60
.L_lambda_opt_env_end_0f60:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f60:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f60
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f60
.L_lambda_opt_params_end_0f60:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f60
	jmp .L_lambda_opt_end_0f60
.L_lambda_opt_code_0f60:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f60 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f60 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f60:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f60:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f60
	.L_lambda_opt_exact_shifting_loop_end_0f60:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f60
	.L_lambda_opt_arity_check_more_0f60:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f60
	.L_lambda_opt_stack_shrink_loop_0f60:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f60:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f60
	.L_lambda_opt_more_shifting_loop_end_0f60:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_0f60
	.L_lambda_opt_stack_shrink_loop_exit_0f60:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f60:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_24]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator
	push rax
	push 2	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f42:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f42
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f42
.L_tc_recycle_frame_done_8f42:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0f60:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d45:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d46:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d46
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d46
.L_lambda_simple_env_end_6d46:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d46:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d46
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d46
.L_lambda_simple_params_end_6d46:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d46
	jmp .L_lambda_simple_end_6d46
.L_lambda_simple_code_6d46:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d46
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d46:
	enter 0, 0
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_128], rax	; free var char<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, qword [free_var_123]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_129], rax	; free var char<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_130], rax	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, qword [free_var_124]	; free var >
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_131], rax	; free var char>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, qword [free_var_125]	; free var >=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_132], rax	; free var char>=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d46:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_133], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_134], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 2538
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2542
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d47:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d47
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d47
.L_lambda_simple_env_end_6d47:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d47:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d47
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d47
.L_lambda_simple_params_end_6d47:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d47
	jmp .L_lambda_simple_end_6d47
.L_lambda_simple_code_6d47:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d47
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d47:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d48:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d48
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d48
.L_lambda_simple_env_end_6d48:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d48:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d48
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d48
.L_lambda_simple_params_end_6d48:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d48
	jmp .L_lambda_simple_end_6d48
.L_lambda_simple_code_6d48:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d48
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d48:
	enter 0, 0
	mov rax, L_constants + 2540
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, L_constants + 2538
	push rax
	push 3	; arg count
	mov rax, qword [free_var_129]	; free var char<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7712
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var delta
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_25]	; free var integer->char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f43:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f43
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f43
.L_tc_recycle_frame_done_8f43:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7712

	.L_if_else_7712:
	mov rax, PARAM(0)	; param ch

	.L_if_end_7712:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d48:	; new closure is in rax
	mov qword [free_var_133], rax	; free var char-downcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d49:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d49
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d49
.L_lambda_simple_env_end_6d49:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d49:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d49
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d49
.L_lambda_simple_params_end_6d49:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d49
	jmp .L_lambda_simple_end_6d49
.L_lambda_simple_code_6d49:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d49
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d49:
	enter 0, 0
	mov rax, L_constants + 2544
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, L_constants + 2542
	push rax
	push 3	; arg count
	mov rax, qword [free_var_129]	; free var char<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7713
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var delta
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_25]	; free var integer->char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f44:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f44
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f44
.L_tc_recycle_frame_done_8f44:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7713

	.L_if_else_7713:
	mov rax, PARAM(0)	; param ch

	.L_if_end_7713:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d49:	; new closure is in rax
	mov qword [free_var_134], rax	; free var char-upcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d47:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_135], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_136], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_137], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_138], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_139], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d4a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d4a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d4a
.L_lambda_simple_env_end_6d4a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d4a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d4a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d4a
.L_lambda_simple_params_end_6d4a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d4a
	jmp .L_lambda_simple_end_6d4a
.L_lambda_simple_code_6d4a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d4a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d4a:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f61:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0f61
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f61
.L_lambda_opt_env_end_0f61:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f61:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f61
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f61
.L_lambda_opt_params_end_0f61:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f61
	jmp .L_lambda_opt_end_0f61
.L_lambda_opt_code_0f61:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f61 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f61 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f61:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f61:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f61
	.L_lambda_opt_exact_shifting_loop_end_0f61:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f61
	.L_lambda_opt_arity_check_more_0f61:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f61
	.L_lambda_opt_stack_shrink_loop_0f61:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f61:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f61
	.L_lambda_opt_more_shifting_loop_end_0f61:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_0f61
	.L_lambda_opt_stack_shrink_loop_exit_0f61:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f61:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d4b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d4b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d4b
.L_lambda_simple_env_end_6d4b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d4b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d4b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d4b
.L_lambda_simple_params_end_6d4b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d4b
	jmp .L_lambda_simple_end_6d4b
.L_lambda_simple_code_6d4b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d4b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d4b:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	push 1	; arg count
	mov rax, qword [free_var_133]	; free var char-downcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f45:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f45
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f45
.L_tc_recycle_frame_done_8f45:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d4b:	; new closure is in rax
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator
	push rax
	push 2	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f46:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f46
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f46
.L_tc_recycle_frame_done_8f46:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0f61:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d4a:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d4c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d4c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d4c
.L_lambda_simple_env_end_6d4c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d4c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d4c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d4c
.L_lambda_simple_params_end_6d4c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d4c
	jmp .L_lambda_simple_end_6d4c
.L_lambda_simple_code_6d4c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d4c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d4c:
	enter 0, 0
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_135], rax	; free var char-ci<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, qword [free_var_123]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_136], rax	; free var char-ci<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_137], rax	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, qword [free_var_124]	; free var >
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_138], rax	; free var char-ci>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, qword [free_var_125]	; free var >=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_139], rax	; free var char-ci>=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d4c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_140], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_141], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d4d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d4d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d4d
.L_lambda_simple_env_end_6d4d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d4d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d4d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d4d
.L_lambda_simple_params_end_6d4d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d4d
	jmp .L_lambda_simple_end_6d4d
.L_lambda_simple_code_6d4d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d4d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d4d:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d4e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d4e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d4e
.L_lambda_simple_env_end_6d4e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d4e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d4e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d4e
.L_lambda_simple_params_end_6d4e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d4e
	jmp .L_lambda_simple_end_6d4e
.L_lambda_simple_code_6d4e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d4e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d4e:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_143]	; free var string->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var char-case-converter
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_142]	; free var list->string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f47:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f47
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f47
.L_tc_recycle_frame_done_8f47:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d4e:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d4d:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d4f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d4f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d4f
.L_lambda_simple_env_end_6d4f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d4f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d4f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d4f
.L_lambda_simple_params_end_6d4f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d4f
	jmp .L_lambda_simple_end_6d4f
.L_lambda_simple_code_6d4f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d4f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d4f:
	enter 0, 0
	mov rax, qword [free_var_133]	; free var char-downcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string-case-converter
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_140], rax	; free var string-downcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, qword [free_var_134]	; free var char-upcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string-case-converter
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_141], rax	; free var string-upcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d4f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_144], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_145], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_146], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_147], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_148], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_149], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_150], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_151], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_152], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_153], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d50:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d50
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d50
.L_lambda_simple_env_end_6d50:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d50:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d50
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d50
.L_lambda_simple_params_end_6d50:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d50
	jmp .L_lambda_simple_end_6d50
.L_lambda_simple_code_6d50:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d50
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d50:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d51:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d51
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d51
.L_lambda_simple_env_end_6d51:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d51:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d51
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d51
.L_lambda_simple_params_end_6d51:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d51
	jmp .L_lambda_simple_end_6d51
.L_lambda_simple_code_6d51:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d51
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d51:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d52:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d52
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d52
.L_lambda_simple_env_end_6d52:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d52:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d52
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d52
.L_lambda_simple_params_end_6d52:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d52
	jmp .L_lambda_simple_end_6d52
.L_lambda_simple_code_6d52:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_6d52
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d52:
	enter 0, 0
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7714
	mov rax, PARAM(4)	; param len2
	push rax
	mov rax, PARAM(2)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7714

	.L_if_else_7714:
	mov rax, L_constants + 2

	.L_if_end_7714:
	cmp rax, sob_boolean_false
	jne .L_or_end_0775
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7715
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0776
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7716
	; preparing a tail-call
	mov rax, PARAM(4)	; param len2
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 5 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f48:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f48
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f48
.L_tc_recycle_frame_done_8f48:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7716

	.L_if_else_7716:
	mov rax, L_constants + 2

	.L_if_end_7716:
.L_or_end_0776:

	jmp .L_if_end_7715

	.L_if_else_7715:
	mov rax, L_constants + 2

	.L_if_end_7715:
.L_or_end_0775:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_6d52:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d53:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d53
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d53
.L_lambda_simple_env_end_6d53:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d53:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d53
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d53
.L_lambda_simple_params_end_6d53:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d53
	jmp .L_lambda_simple_end_6d53
.L_lambda_simple_code_6d53:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d53
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d53:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d54:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_6d54
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d54
.L_lambda_simple_env_end_6d54:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d54:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d54
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d54
.L_lambda_simple_params_end_6d54:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d54
	jmp .L_lambda_simple_end_6d54
.L_lambda_simple_code_6d54:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d54
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d54:
	enter 0, 0
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_123]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7717
	; preparing a tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, L_constants + 2023
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 5 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f49:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f49
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f49
.L_tc_recycle_frame_done_8f49:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7717

	.L_if_else_7717:
	; preparing a tail-call
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, L_constants + 2023
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 5 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f4a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f4a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f4a
.L_tc_recycle_frame_done_8f4a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_7717:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d54:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f4b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f4b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f4b
.L_tc_recycle_frame_done_8f4b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d53:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d55:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d55
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d55
.L_lambda_simple_env_end_6d55:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d55:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d55
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d55
.L_lambda_simple_params_end_6d55:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d55
	jmp .L_lambda_simple_end_6d55
.L_lambda_simple_code_6d55:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d55
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d55:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d56:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_6d56
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d56
.L_lambda_simple_env_end_6d56:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d56:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d56
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d56
.L_lambda_simple_params_end_6d56:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d56
	jmp .L_lambda_simple_end_6d56
.L_lambda_simple_code_6d56:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d56
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d56:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d57:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_6d57
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d57
.L_lambda_simple_env_end_6d57:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d57:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d57
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d57
.L_lambda_simple_params_end_6d57:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d57
	jmp .L_lambda_simple_end_6d57
.L_lambda_simple_code_6d57:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d57
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d57:
	enter 0, 0
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0777
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7718
	; preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f4c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f4c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f4c
.L_tc_recycle_frame_done_8f4c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7718

	.L_if_else_7718:
	mov rax, L_constants + 2

	.L_if_end_7718:
.L_or_end_0777:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d57:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f62:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_opt_env_end_0f62
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f62
.L_lambda_opt_env_end_0f62:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f62:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f62
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f62
.L_lambda_opt_params_end_0f62:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f62
	jmp .L_lambda_opt_end_0f62
.L_lambda_opt_code_0f62:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f62 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f62 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f62:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f62:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f62
	.L_lambda_opt_exact_shifting_loop_end_0f62:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f62
	.L_lambda_opt_arity_check_more_0f62:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f62
	.L_lambda_opt_stack_shrink_loop_0f62:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f62:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f62
	.L_lambda_opt_more_shifting_loop_end_0f62:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0f62
	.L_lambda_opt_stack_shrink_loop_exit_0f62:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f62:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f4d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f4d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f4d
.L_tc_recycle_frame_done_8f4d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0f62:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d56:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f4e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f4e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f4e
.L_tc_recycle_frame_done_8f4e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d55:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f4f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f4f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f4f
.L_tc_recycle_frame_done_8f4f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d51:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f50:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f50
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f50
.L_tc_recycle_frame_done_8f50:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d50:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d58:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d58
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d58
.L_lambda_simple_env_end_6d58:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d58:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d58
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d58
.L_lambda_simple_params_end_6d58:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d58
	jmp .L_lambda_simple_end_6d58
.L_lambda_simple_code_6d58:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d58
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d58:
	enter 0, 0
	mov rax, qword [free_var_130]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_128]	; free var char<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_144], rax	; free var string<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, qword [free_var_137]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_135]	; free var char-ci<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_149], rax	; free var string-ci<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, qword [free_var_130]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_131]	; free var char>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_148], rax	; free var string>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, qword [free_var_137]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_138]	; free var char-ci>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_153], rax	; free var string-ci>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d58:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d59:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d59
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d59
.L_lambda_simple_env_end_6d59:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d59:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d59
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d59
.L_lambda_simple_params_end_6d59:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d59
	jmp .L_lambda_simple_end_6d59
.L_lambda_simple_code_6d59:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d59
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d59:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d5a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d5a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d5a
.L_lambda_simple_env_end_6d5a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d5a:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d5a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d5a
.L_lambda_simple_params_end_6d5a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d5a
	jmp .L_lambda_simple_end_6d5a
.L_lambda_simple_code_6d5a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d5a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d5a:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d5b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d5b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d5b
.L_lambda_simple_env_end_6d5b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d5b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d5b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d5b
.L_lambda_simple_params_end_6d5b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d5b
	jmp .L_lambda_simple_end_6d5b
.L_lambda_simple_code_6d5b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_6d5b
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d5b:
	enter 0, 0
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0778
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0778
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7719
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_771a
	; preparing a tail-call
	mov rax, PARAM(4)	; param len2
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 5 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f51:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f51
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f51
.L_tc_recycle_frame_done_8f51:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_771a

	.L_if_else_771a:
	mov rax, L_constants + 2

	.L_if_end_771a:

	jmp .L_if_end_7719

	.L_if_else_7719:
	mov rax, L_constants + 2

	.L_if_end_7719:
.L_or_end_0778:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_6d5b:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d5c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d5c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d5c
.L_lambda_simple_env_end_6d5c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d5c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d5c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d5c
.L_lambda_simple_params_end_6d5c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d5c
	jmp .L_lambda_simple_end_6d5c
.L_lambda_simple_code_6d5c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d5c
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d5c:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d5d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_6d5d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d5d
.L_lambda_simple_env_end_6d5d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d5d:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d5d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d5d
.L_lambda_simple_params_end_6d5d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d5d
	jmp .L_lambda_simple_end_6d5d
.L_lambda_simple_code_6d5d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d5d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d5d:
	enter 0, 0
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_123]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_771b
	; preparing a tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, L_constants + 2023
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 5 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f52:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f52
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f52
.L_tc_recycle_frame_done_8f52:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_771b

	.L_if_else_771b:
	; preparing a tail-call
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, L_constants + 2023
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 5 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f53:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f53
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f53
.L_tc_recycle_frame_done_8f53:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_771b:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d5d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f54:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f54
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f54
.L_tc_recycle_frame_done_8f54:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d5c:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d5e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d5e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d5e
.L_lambda_simple_env_end_6d5e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d5e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d5e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d5e
.L_lambda_simple_params_end_6d5e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d5e
	jmp .L_lambda_simple_end_6d5e
.L_lambda_simple_code_6d5e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d5e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d5e:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d5f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_6d5f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d5f
.L_lambda_simple_env_end_6d5f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d5f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d5f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d5f
.L_lambda_simple_params_end_6d5f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d5f
	jmp .L_lambda_simple_end_6d5f
.L_lambda_simple_code_6d5f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d5f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d5f:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d60:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_6d60
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d60
.L_lambda_simple_env_end_6d60:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d60:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d60
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d60
.L_lambda_simple_params_end_6d60:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d60
	jmp .L_lambda_simple_end_6d60
.L_lambda_simple_code_6d60:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d60
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d60:
	enter 0, 0
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0779
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_771c
	; preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f55:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f55
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f55
.L_tc_recycle_frame_done_8f55:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_771c

	.L_if_else_771c:
	mov rax, L_constants + 2

	.L_if_end_771c:
.L_or_end_0779:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d60:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f63:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_opt_env_end_0f63
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f63
.L_lambda_opt_env_end_0f63:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f63:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f63
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f63
.L_lambda_opt_params_end_0f63:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f63
	jmp .L_lambda_opt_end_0f63
.L_lambda_opt_code_0f63:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f63 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f63 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f63:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f63:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f63
	.L_lambda_opt_exact_shifting_loop_end_0f63:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f63
	.L_lambda_opt_arity_check_more_0f63:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f63
	.L_lambda_opt_stack_shrink_loop_0f63:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f63:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f63
	.L_lambda_opt_more_shifting_loop_end_0f63:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0f63
	.L_lambda_opt_stack_shrink_loop_exit_0f63:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f63:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f56:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f56
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f56
.L_tc_recycle_frame_done_8f56:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0f63:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d5f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f57:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f57
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f57
.L_tc_recycle_frame_done_8f57:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d5e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f58:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f58
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f58
.L_tc_recycle_frame_done_8f58:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d5a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f59:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f59
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f59
.L_tc_recycle_frame_done_8f59:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d59:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d61:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d61
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d61
.L_lambda_simple_env_end_6d61:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d61:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d61
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d61
.L_lambda_simple_params_end_6d61:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d61
	jmp .L_lambda_simple_end_6d61
.L_lambda_simple_code_6d61:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d61
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d61:
	enter 0, 0
	mov rax, qword [free_var_130]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_128]	; free var char<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_145], rax	; free var string<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, qword [free_var_137]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_135]	; free var char-ci<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_150], rax	; free var string-ci<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, qword [free_var_130]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_131]	; free var char>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_147], rax	; free var string>=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, qword [free_var_137]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_138]	; free var char-ci>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_152], rax	; free var string-ci>=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d61:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d62:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d62
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d62
.L_lambda_simple_env_end_6d62:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d62:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d62
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d62
.L_lambda_simple_params_end_6d62:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d62
	jmp .L_lambda_simple_end_6d62
.L_lambda_simple_code_6d62:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d62
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d62:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d63:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d63
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d63
.L_lambda_simple_env_end_6d63:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d63:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d63
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d63
.L_lambda_simple_params_end_6d63:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d63
	jmp .L_lambda_simple_end_6d63
.L_lambda_simple_code_6d63:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d63
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d63:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d64:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d64
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d64
.L_lambda_simple_env_end_6d64:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d64:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d64
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d64
.L_lambda_simple_params_end_6d64:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d64
	jmp .L_lambda_simple_end_6d64
.L_lambda_simple_code_6d64:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 4
	je .L_lambda_simple_arity_check_ok_6d64
	push qword [rsp + 8 * 2]
	push 4
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d64:
	enter 0, 0
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_077a
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_771d
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(2)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_771e
	; preparing a tail-call
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(2)	; param str2
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 4	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 4 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f5a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f5a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f5a
.L_tc_recycle_frame_done_8f5a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_771e

	.L_if_else_771e:
	mov rax, L_constants + 2

	.L_if_end_771e:

	jmp .L_if_end_771d

	.L_if_else_771d:
	mov rax, L_constants + 2

	.L_if_end_771d:
.L_or_end_077a:
	leave
	ret AND_KILL_FRAME(4)
.L_lambda_simple_end_6d64:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d65:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d65
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d65
.L_lambda_simple_env_end_6d65:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d65:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d65
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d65
.L_lambda_simple_params_end_6d65:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d65
	jmp .L_lambda_simple_end_6d65
.L_lambda_simple_code_6d65:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d65
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d65:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d66:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_6d66
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d66
.L_lambda_simple_env_end_6d66:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d66:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d66
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d66
.L_lambda_simple_params_end_6d66:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d66
	jmp .L_lambda_simple_end_6d66
.L_lambda_simple_code_6d66:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d66
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d66:
	enter 0, 0
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_771f
	; preparing a tail-call
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, L_constants + 2023
	push rax
	push 4	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 4 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f5b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f5b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f5b
.L_tc_recycle_frame_done_8f5b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_771f

	.L_if_else_771f:
	mov rax, L_constants + 2

	.L_if_end_771f:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d66:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f5c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f5c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f5c
.L_tc_recycle_frame_done_8f5c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d65:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d67:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d67
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d67
.L_lambda_simple_env_end_6d67:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d67:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d67
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d67
.L_lambda_simple_params_end_6d67:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d67
	jmp .L_lambda_simple_end_6d67
.L_lambda_simple_code_6d67:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d67
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d67:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d68:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_6d68
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d68
.L_lambda_simple_env_end_6d68:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d68:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d68
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d68
.L_lambda_simple_params_end_6d68:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d68
	jmp .L_lambda_simple_end_6d68
.L_lambda_simple_code_6d68:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d68
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d68:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d69:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_6d69
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d69
.L_lambda_simple_env_end_6d69:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d69:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d69
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d69
.L_lambda_simple_params_end_6d69:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d69
	jmp .L_lambda_simple_end_6d69
.L_lambda_simple_code_6d69:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d69
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d69:
	enter 0, 0
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_077b
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7720
	; preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f5d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f5d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f5d
.L_tc_recycle_frame_done_8f5d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7720

	.L_if_else_7720:
	mov rax, L_constants + 2

	.L_if_end_7720:
.L_or_end_077b:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d69:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f64:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_opt_env_end_0f64
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f64
.L_lambda_opt_env_end_0f64:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f64:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f64
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f64
.L_lambda_opt_params_end_0f64:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f64
	jmp .L_lambda_opt_end_0f64
.L_lambda_opt_code_0f64:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f64 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f64 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f64:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f64:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f64
	.L_lambda_opt_exact_shifting_loop_end_0f64:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f64
	.L_lambda_opt_arity_check_more_0f64:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f64
	.L_lambda_opt_stack_shrink_loop_0f64:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f64:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f64
	.L_lambda_opt_more_shifting_loop_end_0f64:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0f64
	.L_lambda_opt_stack_shrink_loop_exit_0f64:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f64:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f5e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f5e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f5e
.L_tc_recycle_frame_done_8f5e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0f64:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d68:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f5f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f5f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f5f
.L_tc_recycle_frame_done_8f5f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d67:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f60:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f60
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f60
.L_tc_recycle_frame_done_8f60:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d63:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f61:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f61
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f61
.L_tc_recycle_frame_done_8f61:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d62:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d6a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d6a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d6a
.L_lambda_simple_env_end_6d6a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d6a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d6a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d6a
.L_lambda_simple_params_end_6d6a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d6a
	jmp .L_lambda_simple_end_6d6a
.L_lambda_simple_code_6d6a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d6a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d6a:
	enter 0, 0
	mov rax, qword [free_var_130]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_146], rax	; free var string=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void

	mov rax, qword [free_var_137]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_151], rax	; free var string-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d6a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d6b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d6b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d6b
.L_lambda_simple_env_end_6d6b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d6b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d6b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d6b
.L_lambda_simple_params_end_6d6b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d6b
	jmp .L_lambda_simple_end_6d6b
.L_lambda_simple_code_6d6b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d6b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d6b:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7721
	mov rax, L_constants + 2023

	jmp .L_if_end_7721

	.L_if_else_7721:
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_154]	; free var length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2158
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f62:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f62
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f62
.L_tc_recycle_frame_done_8f62:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_7721:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d6b:	; new closure is in rax
	mov qword [free_var_154], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d6c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d6c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d6c
.L_lambda_simple_env_end_6d6c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d6c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d6c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d6c
.L_lambda_simple_params_end_6d6c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d6c
	jmp .L_lambda_simple_end_6d6c
.L_lambda_simple_code_6d6c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d6c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d6c:
	enter 0, 0
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_077c
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7722
	; preparing a tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_102]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f63:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f63
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f63
.L_tc_recycle_frame_done_8f63:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7722

	.L_if_else_7722:
	mov rax, L_constants + 2

	.L_if_end_7722:
.L_or_end_077c:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d6c:	; new closure is in rax
	mov qword [free_var_102], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, qword [free_var_57]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d6d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d6d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d6d
.L_lambda_simple_env_end_6d6d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d6d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d6d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d6d
.L_lambda_simple_params_end_6d6d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d6d
	jmp .L_lambda_simple_end_6d6d
.L_lambda_simple_code_6d6d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d6d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d6d:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f65:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0f65
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f65
.L_lambda_opt_env_end_0f65:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f65:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f65
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f65
.L_lambda_opt_params_end_0f65:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f65
	jmp .L_lambda_opt_end_0f65
.L_lambda_opt_code_0f65:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f65 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f65 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f65:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f65:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f65
	.L_lambda_opt_exact_shifting_loop_end_0f65:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f65
	.L_lambda_opt_arity_check_more_0f65:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f65
	.L_lambda_opt_stack_shrink_loop_0f65:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f65:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f65
	.L_lambda_opt_more_shifting_loop_end_0f65:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0f65
	.L_lambda_opt_stack_shrink_loop_exit_0f65:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f65:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7723
	mov rax, L_constants + 0

	jmp .L_if_end_7723

	.L_if_else_7723:
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7725
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7725

	.L_if_else_7725:
	mov rax, L_constants + 2

	.L_if_end_7725:

	cmp rax, sob_boolean_false
	je .L_if_else_7724
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7724

	.L_if_else_7724:
	mov rax, L_constants + 2939
	push rax
	mov rax, L_constants + 2930
	push rax
	push 2	; arg count
	mov rax, qword [free_var_42]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	.L_if_end_7724:

	.L_if_end_7723:
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d6e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d6e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d6e
.L_lambda_simple_env_end_6d6e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d6e:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d6e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d6e
.L_lambda_simple_params_end_6d6e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d6e
	jmp .L_lambda_simple_end_6d6e
.L_lambda_simple_code_6d6e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d6e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d6e:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var asm-make-vector
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f64:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f64
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f64
.L_tc_recycle_frame_done_8f64:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d6e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f65:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f65
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f65
.L_tc_recycle_frame_done_8f65:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0f65:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d6d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_57], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, qword [free_var_58]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d6f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d6f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d6f
.L_lambda_simple_env_end_6d6f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d6f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d6f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d6f
.L_lambda_simple_params_end_6d6f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d6f
	jmp .L_lambda_simple_end_6d6f
.L_lambda_simple_code_6d6f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d6f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d6f:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f66:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0f66
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f66
.L_lambda_opt_env_end_0f66:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f66:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_0f66
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f66
.L_lambda_opt_params_end_0f66:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f66
	jmp .L_lambda_opt_end_0f66
.L_lambda_opt_code_0f66:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f66 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f66 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f66:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f66:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f66
	.L_lambda_opt_exact_shifting_loop_end_0f66:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f66
	.L_lambda_opt_arity_check_more_0f66:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f66
	.L_lambda_opt_stack_shrink_loop_0f66:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f66:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f66
	.L_lambda_opt_more_shifting_loop_end_0f66:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_0f66
	.L_lambda_opt_stack_shrink_loop_exit_0f66:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f66:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7726
	mov rax, L_constants + 4

	jmp .L_if_end_7726

	.L_if_else_7726:
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7728
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7728

	.L_if_else_7728:
	mov rax, L_constants + 2

	.L_if_end_7728:

	cmp rax, sob_boolean_false
	je .L_if_else_7727
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7727

	.L_if_else_7727:
	mov rax, L_constants + 3000
	push rax
	mov rax, L_constants + 2991
	push rax
	push 2	; arg count
	mov rax, qword [free_var_42]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	.L_if_end_7727:

	.L_if_end_7726:
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d70:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d70
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d70
.L_lambda_simple_env_end_6d70:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d70:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d70
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d70
.L_lambda_simple_params_end_6d70:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d70
	jmp .L_lambda_simple_end_6d70
.L_lambda_simple_code_6d70:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d70
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d70:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var asm-make-string
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f66:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f66
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f66
.L_tc_recycle_frame_done_8f66:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d70:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f67:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f67
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f67
.L_tc_recycle_frame_done_8f67:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_0f66:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d6f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_58], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d71:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d71
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d71
.L_lambda_simple_env_end_6d71:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d71:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d71
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d71
.L_lambda_simple_params_end_6d71:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d71
	jmp .L_lambda_simple_end_6d71
.L_lambda_simple_code_6d71:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d71
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d71:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d72:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d72
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d72
.L_lambda_simple_env_end_6d72:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d72:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d72
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d72
.L_lambda_simple_params_end_6d72:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d72
	jmp .L_lambda_simple_end_6d72
.L_lambda_simple_code_6d72:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d72
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d72:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7729
	; preparing a tail-call
	mov rax, L_constants + 0
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_57]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f68:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f68
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f68
.L_tc_recycle_frame_done_8f68:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7729

	.L_if_else_7729:
	; preparing a tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d73:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d73
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d73
.L_lambda_simple_env_end_6d73:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d73:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d73
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d73
.L_lambda_simple_params_end_6d73:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d73
	jmp .L_lambda_simple_end_6d73
.L_lambda_simple_code_6d73:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d73
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d73:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3	; arg count
	mov rax, qword [free_var_55]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param v
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d73:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f69:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f69
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f69
.L_tc_recycle_frame_done_8f69:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_7729:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d72:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d74:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d74
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d74
.L_lambda_simple_env_end_6d74:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d74:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d74
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d74
.L_lambda_simple_params_end_6d74:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d74
	jmp .L_lambda_simple_end_6d74
.L_lambda_simple_code_6d74:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d74
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d74:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2023
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f6a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f6a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f6a
.L_tc_recycle_frame_done_8f6a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d74:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d71:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_155], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d75:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d75
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d75
.L_lambda_simple_env_end_6d75:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d75:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d75
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d75
.L_lambda_simple_params_end_6d75:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d75
	jmp .L_lambda_simple_end_6d75
.L_lambda_simple_code_6d75:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d75
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d75:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d76:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d76
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d76
.L_lambda_simple_env_end_6d76:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d76:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d76
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d76
.L_lambda_simple_params_end_6d76:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d76
	jmp .L_lambda_simple_end_6d76
.L_lambda_simple_code_6d76:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d76
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d76:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_772a
	; preparing a tail-call
	mov rax, L_constants + 4
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_58]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f6b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f6b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f6b
.L_tc_recycle_frame_done_8f6b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_772a

	.L_if_else_772a:
	; preparing a tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d77:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d77
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d77
.L_lambda_simple_env_end_6d77:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d77:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d77
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d77
.L_lambda_simple_params_end_6d77:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d77
	jmp .L_lambda_simple_end_6d77
.L_lambda_simple_code_6d77:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d77
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d77:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3	; arg count
	mov rax, qword [free_var_56]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param str
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d77:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f6c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f6c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f6c
.L_tc_recycle_frame_done_8f6c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_772a:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d76:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d78:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d78
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d78
.L_lambda_simple_env_end_6d78:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d78:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d78
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d78
.L_lambda_simple_params_end_6d78:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d78
	jmp .L_lambda_simple_end_6d78
.L_lambda_simple_code_6d78:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d78
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d78:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2023
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f6d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f6d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f6d
.L_tc_recycle_frame_done_8f6d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d78:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d75:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_142], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f67:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_0f67
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f67
.L_lambda_opt_env_end_0f67:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f67:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_0f67
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f67
.L_lambda_opt_params_end_0f67:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f67
	jmp .L_lambda_opt_end_0f67
.L_lambda_opt_code_0f67:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f67 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f67 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f67:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f67:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f67
	.L_lambda_opt_exact_shifting_loop_end_0f67:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f67
	.L_lambda_opt_arity_check_more_0f67:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f67
	.L_lambda_opt_stack_shrink_loop_0f67:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f67:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f67
	.L_lambda_opt_more_shifting_loop_end_0f67:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_0f67
	.L_lambda_opt_stack_shrink_loop_exit_0f67:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f67:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_155]	; free var list->vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f6e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f6e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f6e
.L_tc_recycle_frame_done_8f6e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0f67:	; new closure is in rax
	mov qword [free_var_156], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d79:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d79
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d79
.L_lambda_simple_env_end_6d79:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d79:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d79
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d79
.L_lambda_simple_params_end_6d79:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d79
	jmp .L_lambda_simple_end_6d79
.L_lambda_simple_code_6d79:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d79
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d79:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d7a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d7a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d7a
.L_lambda_simple_env_end_6d7a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d7a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d7a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d7a
.L_lambda_simple_params_end_6d7a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d7a
	jmp .L_lambda_simple_end_6d7a
.L_lambda_simple_code_6d7a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_6d7a
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d7a:
	enter 0, 0
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_772b
	; preparing a tail-call
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f6f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f6f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f6f
.L_tc_recycle_frame_done_8f6f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_772b

	.L_if_else_772b:
	mov rax, L_constants + 1

	.L_if_end_772b:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_6d7a:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d7b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d7b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d7b
.L_lambda_simple_env_end_6d7b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d7b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d7b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d7b
.L_lambda_simple_params_end_6d7b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d7b
	jmp .L_lambda_simple_end_6d7b
.L_lambda_simple_code_6d7b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d7b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d7b:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2023
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f70:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f70
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f70
.L_tc_recycle_frame_done_8f70:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d7b:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d79:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_143], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d7c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d7c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d7c
.L_lambda_simple_env_end_6d7c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d7c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d7c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d7c
.L_lambda_simple_params_end_6d7c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d7c
	jmp .L_lambda_simple_end_6d7c
.L_lambda_simple_code_6d7c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d7c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d7c:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d7d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d7d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d7d
.L_lambda_simple_env_end_6d7d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d7d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d7d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d7d
.L_lambda_simple_params_end_6d7d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d7d
	jmp .L_lambda_simple_end_6d7d
.L_lambda_simple_code_6d7d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_6d7d
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d7d:
	enter 0, 0
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_772c
	; preparing a tail-call
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 2	; arg count
	mov rax, qword [free_var_54]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f71:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f71
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f71
.L_tc_recycle_frame_done_8f71:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_772c

	.L_if_else_772c:
	mov rax, L_constants + 1

	.L_if_end_772c:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_6d7d:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d7e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d7e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d7e
.L_lambda_simple_env_end_6d7e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d7e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d7e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d7e
.L_lambda_simple_params_end_6d7e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d7e
	jmp .L_lambda_simple_end_6d7e
.L_lambda_simple_code_6d7e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d7e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d7e:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param v
	push rax
	push 1	; arg count
	mov rax, qword [free_var_19]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2023
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f72:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f72
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f72
.L_tc_recycle_frame_done_8f72:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d7e:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d7c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_157], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d7f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d7f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d7f
.L_lambda_simple_env_end_6d7f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d7f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d7f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d7f
.L_lambda_simple_params_end_6d7f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d7f
	jmp .L_lambda_simple_end_6d7f
.L_lambda_simple_code_6d7f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d7f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d7f:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 0	; arg count
	mov rax, qword [free_var_26]	; free var trng
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_50]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f73:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f73
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f73
.L_tc_recycle_frame_done_8f73:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d7f:	; new closure is in rax
	mov qword [free_var_158], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d80:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d80
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d80
.L_lambda_simple_env_end_6d80:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d80:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d80
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d80
.L_lambda_simple_params_end_6d80:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d80
	jmp .L_lambda_simple_end_6d80
.L_lambda_simple_code_6d80:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d80
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d80:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, L_constants + 2023
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f74:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f74
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f74
.L_tc_recycle_frame_done_8f74:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d80:	; new closure is in rax
	mov qword [free_var_159], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d81:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d81
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d81
.L_lambda_simple_env_end_6d81:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d81:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d81
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d81
.L_lambda_simple_params_end_6d81:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d81
	jmp .L_lambda_simple_end_6d81
.L_lambda_simple_code_6d81:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d81
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d81:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2023
	push rax
	mov rax, PARAM(0)	; param x
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f75:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f75
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f75
.L_tc_recycle_frame_done_8f75:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d81:	; new closure is in rax
	mov qword [free_var_160], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d82:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d82
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d82
.L_lambda_simple_env_end_6d82:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d82:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d82
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d82
.L_lambda_simple_params_end_6d82:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d82
	jmp .L_lambda_simple_end_6d82
.L_lambda_simple_code_6d82:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d82
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d82:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 3174
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_50]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_27]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f76:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f76
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f76
.L_tc_recycle_frame_done_8f76:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d82:	; new closure is in rax
	mov qword [free_var_161], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d83:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d83
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d83
.L_lambda_simple_env_end_6d83:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d83:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d83
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d83
.L_lambda_simple_params_end_6d83:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d83
	jmp .L_lambda_simple_end_6d83
.L_lambda_simple_code_6d83:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d83
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d83:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_161]	; free var even?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_104]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f77:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f77
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f77
.L_tc_recycle_frame_done_8f77:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d83:	; new closure is in rax
	mov qword [free_var_162], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d84:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d84
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d84
.L_lambda_simple_env_end_6d84:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d84:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d84
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d84
.L_lambda_simple_params_end_6d84:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d84
	jmp .L_lambda_simple_end_6d84
.L_lambda_simple_code_6d84:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d84
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d84:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_160]	; free var negative?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_772d
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f78:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f78
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f78
.L_tc_recycle_frame_done_8f78:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_772d

	.L_if_else_772d:
	mov rax, PARAM(0)	; param x

	.L_if_end_772d:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d84:	; new closure is in rax
	mov qword [free_var_163], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d85:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d85
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d85
.L_lambda_simple_env_end_6d85:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d85:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d85
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d85
.L_lambda_simple_params_end_6d85:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d85
	jmp .L_lambda_simple_end_6d85
.L_lambda_simple_code_6d85:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d85
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d85:
	enter 0, 0
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_772f
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_772f

	.L_if_else_772f:
	mov rax, L_constants + 2

	.L_if_end_772f:

	cmp rax, sob_boolean_false
	je .L_if_else_772e
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_164]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7730
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_164]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f79:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f79
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f79
.L_tc_recycle_frame_done_8f79:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7730

	.L_if_else_7730:
	mov rax, L_constants + 2

	.L_if_end_7730:

	jmp .L_if_end_772e

	.L_if_else_772e:
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_6]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7732
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_6]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7733
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_19]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_19]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7733

	.L_if_else_7733:
	mov rax, L_constants + 2

	.L_if_end_7733:

	jmp .L_if_end_7732

	.L_if_else_7732:
	mov rax, L_constants + 2

	.L_if_end_7732:

	cmp rax, sob_boolean_false
	je .L_if_else_7731
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_157]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_157]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_164]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f7a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f7a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f7a
.L_tc_recycle_frame_done_8f7a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7731

	.L_if_else_7731:
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_4]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7735
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_4]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7736
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7736

	.L_if_else_7736:
	mov rax, L_constants + 2

	.L_if_end_7736:

	jmp .L_if_end_7735

	.L_if_else_7735:
	mov rax, L_constants + 2

	.L_if_end_7735:

	cmp rax, sob_boolean_false
	je .L_if_else_7734
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_146]	; free var string=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f7b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f7b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f7b
.L_tc_recycle_frame_done_8f7b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7734

	.L_if_else_7734:
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_11]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7738
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_11]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7738

	.L_if_else_7738:
	mov rax, L_constants + 2

	.L_if_end_7738:

	cmp rax, sob_boolean_false
	je .L_if_else_7737
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f7c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f7c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f7c
.L_tc_recycle_frame_done_8f7c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7737

	.L_if_else_7737:
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_3]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_773a
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_3]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_773a

	.L_if_else_773a:
	mov rax, L_constants + 2

	.L_if_end_773a:

	cmp rax, sob_boolean_false
	je .L_if_else_7739
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_130]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f7d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f7d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f7d
.L_tc_recycle_frame_done_8f7d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7739

	.L_if_else_7739:
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_61]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f7e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f7e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f7e
.L_tc_recycle_frame_done_8f7e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_7739:

	.L_if_end_7737:

	.L_if_end_7734:

	.L_if_end_7731:

	.L_if_end_772e:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d85:	; new closure is in rax
	mov qword [free_var_164], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d86:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d86
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d86
.L_lambda_simple_env_end_6d86:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d86:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d86
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d86
.L_lambda_simple_params_end_6d86:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d86
	jmp .L_lambda_simple_end_6d86
.L_lambda_simple_code_6d86:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d86
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d86:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_773b
	mov rax, L_constants + 2

	jmp .L_if_end_773b

	.L_if_else_773b:
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_61]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_773c
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f7f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f7f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f7f
.L_tc_recycle_frame_done_8f7f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_773c

	.L_if_else_773c:
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_165]	; free var assoc
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f80:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f80
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f80
.L_tc_recycle_frame_done_8f80:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_773c:

	.L_if_end_773b:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d86:	; new closure is in rax
	mov qword [free_var_165], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1881
	push rax
	mov rax, L_constants + 1881
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d87:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d87
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d87
.L_lambda_simple_env_end_6d87:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d87:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d87
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d87
.L_lambda_simple_params_end_6d87:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d87
	jmp .L_lambda_simple_end_6d87
.L_lambda_simple_code_6d87:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d87
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d87:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void


	mov rdi, 8
	call malloc
	mov rbx, PARAM(1)	; param add
	mov [rax], rbx	; box add
	mov PARAM(1), rax	;replace param add with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d88:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d88
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d88
.L_lambda_simple_env_end_6d88:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d88:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d88
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d88
.L_lambda_simple_params_end_6d88:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d88
	jmp .L_lambda_simple_end_6d88
.L_lambda_simple_code_6d88:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_6d88
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d88:
	enter 0, 0
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_773d
	mov rax, PARAM(0)	; param target

	jmp .L_if_end_773d

	.L_if_else_773d:
	; preparing a tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2023
	push rax
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d89:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d89
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d89
.L_lambda_simple_env_end_6d89:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d89:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_6d89
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d89
.L_lambda_simple_params_end_6d89:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d89
	jmp .L_lambda_simple_end_6d89
.L_lambda_simple_code_6d89:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d89
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d89:
	enter 0, 0
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var target
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f81:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f81
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f81
.L_tc_recycle_frame_done_8f81:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d89:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f82:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f82
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f82
.L_tc_recycle_frame_done_8f82:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_773d:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_6d88:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d8a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d8a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d8a
.L_lambda_simple_env_end_6d8a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d8a:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d8a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d8a
.L_lambda_simple_params_end_6d8a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d8a
	jmp .L_lambda_simple_end_6d8a
.L_lambda_simple_code_6d8a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_6d8a
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d8a:
	enter 0, 0
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_773e
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 3	; arg count
	mov rax, qword [free_var_56]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 5 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f83:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f83
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f83
.L_tc_recycle_frame_done_8f83:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_773e

	.L_if_else_773e:
	mov rax, PARAM(1)	; param i

	.L_if_end_773e:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_6d8a:	; new closure is in rax

	push rax
	mov rax, PARAM(1)	; param add

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f68:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0f68
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f68
.L_lambda_opt_env_end_0f68:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f68:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_0f68
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f68
.L_lambda_opt_params_end_0f68:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f68
	jmp .L_lambda_opt_end_0f68
.L_lambda_opt_code_0f68:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f68 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f68 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f68:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f68:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f68
	.L_lambda_opt_exact_shifting_loop_end_0f68:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f68
	.L_lambda_opt_arity_check_more_0f68:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f68
	.L_lambda_opt_stack_shrink_loop_0f68:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f68:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f68
	.L_lambda_opt_more_shifting_loop_end_0f68:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_0f68
	.L_lambda_opt_stack_shrink_loop_exit_0f68:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f68:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param strings
	push rax
	mov rax, L_constants + 2023
	push rax
	mov rax, PARAM(0)	; param strings
	push rax
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_58]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f84:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f84
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f84
.L_tc_recycle_frame_done_8f84:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0f68:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d87:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_166], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1881
	push rax
	mov rax, L_constants + 1881
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d8b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d8b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d8b
.L_lambda_simple_env_end_6d8b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d8b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d8b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d8b
.L_lambda_simple_params_end_6d8b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d8b
	jmp .L_lambda_simple_end_6d8b
.L_lambda_simple_code_6d8b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d8b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d8b:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void


	mov rdi, 8
	call malloc
	mov rbx, PARAM(1)	; param add
	mov [rax], rbx	; box add
	mov PARAM(1), rax	;replace param add with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d8c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d8c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d8c
.L_lambda_simple_env_end_6d8c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d8c:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d8c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d8c
.L_lambda_simple_params_end_6d8c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d8c
	jmp .L_lambda_simple_end_6d8c
.L_lambda_simple_code_6d8c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_6d8c
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d8c:
	enter 0, 0
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_773f
	mov rax, PARAM(0)	; param target

	jmp .L_if_end_773f

	.L_if_else_773f:
	; preparing a tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_19]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2023
	push rax
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d8d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d8d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d8d
.L_lambda_simple_env_end_6d8d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d8d:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_6d8d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d8d
.L_lambda_simple_params_end_6d8d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d8d
	jmp .L_lambda_simple_end_6d8d
.L_lambda_simple_code_6d8d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d8d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d8d:
	enter 0, 0
	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var target
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f85:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f85
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f85
.L_tc_recycle_frame_done_8f85:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d8d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f86:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f86
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f86
.L_tc_recycle_frame_done_8f86:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_773f:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_6d8c:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d8e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d8e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d8e
.L_lambda_simple_env_end_6d8e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d8e:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d8e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d8e
.L_lambda_simple_params_end_6d8e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d8e
	jmp .L_lambda_simple_end_6d8e
.L_lambda_simple_code_6d8e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_6d8e
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d8e:
	enter 0, 0
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7740
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	push 2	; arg count
	mov rax, qword [free_var_54]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 3	; arg count
	mov rax, qword [free_var_55]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 5 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f87:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f87
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f87
.L_tc_recycle_frame_done_8f87:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7740

	.L_if_else_7740:
	mov rax, PARAM(1)	; param i

	.L_if_end_7740:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_6d8e:	; new closure is in rax

	push rax
	mov rax, PARAM(1)	; param add

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_0f69:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_0f69
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_0f69
.L_lambda_opt_env_end_0f69:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_0f69:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_0f69
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_0f69
.L_lambda_opt_params_end_0f69:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_0f69
	jmp .L_lambda_opt_end_0f69
.L_lambda_opt_code_0f69:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_0f69 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_0f69 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_0f69:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_0f69:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_0f69
	.L_lambda_opt_exact_shifting_loop_end_0f69:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_0f69
	.L_lambda_opt_arity_check_more_0f69:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_0f69
	.L_lambda_opt_stack_shrink_loop_0f69:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_0f69:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_0f69
	.L_lambda_opt_more_shifting_loop_end_0f69:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_0f69
	.L_lambda_opt_stack_shrink_loop_exit_0f69:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_0f69:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param vectors
	push rax
	mov rax, L_constants + 2023
	push rax
	mov rax, PARAM(0)	; param vectors
	push rax
	mov rax, qword [free_var_19]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_57]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f88:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f88
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f88
.L_tc_recycle_frame_done_8f88:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_0f69:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d8b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_167], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d8f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d8f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d8f
.L_lambda_simple_env_end_6d8f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d8f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d8f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d8f
.L_lambda_simple_params_end_6d8f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d8f
	jmp .L_lambda_simple_end_6d8f
.L_lambda_simple_code_6d8f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d8f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d8f:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_143]	; free var string->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_142]	; free var list->string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f89:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f89
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f89
.L_tc_recycle_frame_done_8f89:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d8f:	; new closure is in rax
	mov qword [free_var_168], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d90:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d90
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d90
.L_lambda_simple_env_end_6d90:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d90:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d90
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d90
.L_lambda_simple_params_end_6d90:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d90
	jmp .L_lambda_simple_end_6d90
.L_lambda_simple_code_6d90:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d90
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d90:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param vec
	push rax
	push 1	; arg count
	mov rax, qword [free_var_157]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_155]	; free var list->vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f8a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f8a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f8a
.L_tc_recycle_frame_done_8f8a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d90:	; new closure is in rax
	mov qword [free_var_169], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d91:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d91
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d91
.L_lambda_simple_env_end_6d91:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d91:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d91
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d91
.L_lambda_simple_params_end_6d91:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d91
	jmp .L_lambda_simple_end_6d91
.L_lambda_simple_code_6d91:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d91
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d91:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d92:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d92
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d92
.L_lambda_simple_env_end_6d92:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d92:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d92
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d92
.L_lambda_simple_params_end_6d92:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d92
	jmp .L_lambda_simple_end_6d92
.L_lambda_simple_code_6d92:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_6d92
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d92:
	enter 0, 0
	mov rax, PARAM(2)	; param j
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7741
	; preparing a tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d93:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d93
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d93
.L_lambda_simple_env_end_6d93:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d93:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_6d93
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d93
.L_lambda_simple_params_end_6d93:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d93
	jmp .L_lambda_simple_end_6d93
.L_lambda_simple_code_6d93:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d93
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d93:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, qword [free_var_56]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, qword [free_var_56]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2158
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f8b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f8b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f8b
.L_tc_recycle_frame_done_8f8b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d93:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f8c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f8c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f8c
.L_tc_recycle_frame_done_8f8c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7741

	.L_if_else_7741:
	mov rax, PARAM(0)	; param str

	.L_if_end_7741:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_6d92:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d94:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d94
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d94
.L_lambda_simple_env_end_6d94:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d94:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d94
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d94
.L_lambda_simple_params_end_6d94:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d94
	jmp .L_lambda_simple_end_6d94
.L_lambda_simple_code_6d94:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d94
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d94:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d95:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d95
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d95
.L_lambda_simple_env_end_6d95:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d95:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d95
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d95
.L_lambda_simple_params_end_6d95:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d95
	jmp .L_lambda_simple_end_6d95
.L_lambda_simple_code_6d95:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d95
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d95:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_27]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7742
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str

	jmp .L_if_end_7742

	.L_if_else_7742:
	; preparing a tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2023
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f8d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f8d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f8d
.L_tc_recycle_frame_done_8f8d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_7742:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d95:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f8e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f8e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f8e
.L_tc_recycle_frame_done_8f8e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d94:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d91:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_170], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d96:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d96
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d96
.L_lambda_simple_env_end_6d96:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d96:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d96
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d96
.L_lambda_simple_params_end_6d96:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d96
	jmp .L_lambda_simple_end_6d96
.L_lambda_simple_code_6d96:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d96
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d96:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d97:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d97
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d97
.L_lambda_simple_env_end_6d97:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d97:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d97
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d97
.L_lambda_simple_params_end_6d97:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d97
	jmp .L_lambda_simple_end_6d97
.L_lambda_simple_code_6d97:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_6d97
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d97:
	enter 0, 0
	mov rax, PARAM(2)	; param j
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7743
	; preparing a tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param vec
	push rax
	push 2	; arg count
	mov rax, qword [free_var_54]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d98:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d98
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d98
.L_lambda_simple_env_end_6d98:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d98:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_6d98
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d98
.L_lambda_simple_params_end_6d98:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d98
	jmp .L_lambda_simple_end_6d98
.L_lambda_simple_code_6d98:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d98
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d98:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 2	; arg count
	mov rax, qword [free_var_54]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, qword [free_var_55]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, qword [free_var_55]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2158
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f8f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f8f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f8f
.L_tc_recycle_frame_done_8f8f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d98:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f90:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f90
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f90
.L_tc_recycle_frame_done_8f90:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7743

	.L_if_else_7743:
	mov rax, PARAM(0)	; param vec

	.L_if_end_7743:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_6d97:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d99:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d99
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d99
.L_lambda_simple_env_end_6d99:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d99:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d99
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d99
.L_lambda_simple_params_end_6d99:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d99
	jmp .L_lambda_simple_end_6d99
.L_lambda_simple_code_6d99:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d99
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d99:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param vec
	push rax
	push 1	; arg count
	mov rax, qword [free_var_19]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d9a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d9a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d9a
.L_lambda_simple_env_end_6d9a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d9a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d9a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d9a
.L_lambda_simple_params_end_6d9a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d9a
	jmp .L_lambda_simple_end_6d9a
.L_lambda_simple_code_6d9a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d9a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d9a:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_27]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7744
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec

	jmp .L_if_end_7744

	.L_if_else_7744:
	; preparing a tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2023
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f91:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f91
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f91
.L_tc_recycle_frame_done_8f91:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_7744:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d9a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f92:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f92
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f92
.L_tc_recycle_frame_done_8f92:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d99:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d96:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_171], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d9b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d9b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d9b
.L_lambda_simple_env_end_6d9b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d9b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d9b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d9b
.L_lambda_simple_params_end_6d9b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d9b
	jmp .L_lambda_simple_end_6d9b
.L_lambda_simple_code_6d9b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d9b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d9b:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d9c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d9c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d9c
.L_lambda_simple_env_end_6d9c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d9c:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d9c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d9c
.L_lambda_simple_params_end_6d9c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d9c
	jmp .L_lambda_simple_end_6d9c
.L_lambda_simple_code_6d9c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d9c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d9c:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d9d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6d9d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d9d
.L_lambda_simple_env_end_6d9d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d9d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6d9d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d9d
.L_lambda_simple_params_end_6d9d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d9d
	jmp .L_lambda_simple_end_6d9d
.L_lambda_simple_code_6d9d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d9d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d9d:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7745
	; preparing a tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var thunk
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f93:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f93
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f93
.L_tc_recycle_frame_done_8f93:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7745

	.L_if_else_7745:
	mov rax, L_constants + 1

	.L_if_end_7745:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d9d:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rax, L_constants + 2023
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f94:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f94
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f94
.L_tc_recycle_frame_done_8f94:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d9c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f95:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f95
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f95
.L_tc_recycle_frame_done_8f95:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d9b:	; new closure is in rax
	mov qword [free_var_172], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d9e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6d9e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d9e
.L_lambda_simple_env_end_6d9e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d9e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6d9e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d9e
.L_lambda_simple_params_end_6d9e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d9e
	jmp .L_lambda_simple_end_6d9e
.L_lambda_simple_code_6d9e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6d9e
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d9e:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_58]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6d9f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6d9f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6d9f
.L_lambda_simple_env_end_6d9f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6d9f:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6d9f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6d9f
.L_lambda_simple_params_end_6d9f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6d9f
	jmp .L_lambda_simple_end_6d9f
.L_lambda_simple_code_6d9f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6d9f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6d9f:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6da0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6da0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6da0
.L_lambda_simple_env_end_6da0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6da0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6da0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6da0
.L_lambda_simple_params_end_6da0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6da0
	jmp .L_lambda_simple_end_6da0
.L_lambda_simple_code_6da0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6da0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6da0:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6da1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_6da1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6da1
.L_lambda_simple_env_end_6da1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6da1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6da1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6da1
.L_lambda_simple_params_end_6da1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6da1
	jmp .L_lambda_simple_end_6da1
.L_lambda_simple_code_6da1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6da1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6da1:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7746
	mov rax, PARAM(0)	; param i
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var thunk
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, qword [free_var_56]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f96:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f96
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f96
.L_tc_recycle_frame_done_8f96:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7746

	.L_if_else_7746:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str

	.L_if_end_7746:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6da1:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rax, L_constants + 2023
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f97:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f97
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f97
.L_tc_recycle_frame_done_8f97:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6da0:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f98:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f98
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f98
.L_tc_recycle_frame_done_8f98:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6d9f:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f99:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f99
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f99
.L_tc_recycle_frame_done_8f99:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6d9e:	; new closure is in rax
	mov qword [free_var_173], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6da2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6da2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6da2
.L_lambda_simple_env_end_6da2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6da2:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6da2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6da2
.L_lambda_simple_params_end_6da2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6da2
	jmp .L_lambda_simple_end_6da2
.L_lambda_simple_code_6da2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_6da2
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6da2:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_57]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6da3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_6da3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6da3
.L_lambda_simple_env_end_6da3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6da3:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_6da3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6da3
.L_lambda_simple_params_end_6da3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6da3
	jmp .L_lambda_simple_end_6da3
.L_lambda_simple_code_6da3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6da3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6da3:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6da4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_6da4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6da4
.L_lambda_simple_env_end_6da4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6da4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6da4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6da4
.L_lambda_simple_params_end_6da4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6da4
	jmp .L_lambda_simple_end_6da4
.L_lambda_simple_code_6da4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6da4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6da4:
	enter 0, 0

	mov rdi, 8
	call malloc
	mov rbx, PARAM(0)	; param run
	mov [rax], rbx	; box run
	mov PARAM(0), rax	;replace param run with box
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6da5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_6da5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6da5
.L_lambda_simple_env_end_6da5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6da5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_6da5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6da5
.L_lambda_simple_params_end_6da5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6da5
	jmp .L_lambda_simple_end_6da5
.L_lambda_simple_code_6da5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_6da5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6da5:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7747
	mov rax, PARAM(0)	; param i
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var thunk
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, qword [free_var_55]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f9a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f9a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f9a
.L_tc_recycle_frame_done_8f9a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7747

	.L_if_else_7747:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec

	.L_if_end_7747:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6da5:	; new closure is in rax

	push rax
	mov rax, PARAM(0)	; param run

	pop qword[rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rax, L_constants + 2023
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f9b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f9b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f9b
.L_tc_recycle_frame_done_8f9b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6da4:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f9c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f9c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f9c
.L_tc_recycle_frame_done_8f9c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_6da3:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f9d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f9d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f9d
.L_tc_recycle_frame_done_8f9d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_6da2:	; new closure is in rax
	mov qword [free_var_174], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6da6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6da6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6da6
.L_lambda_simple_env_end_6da6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6da6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6da6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6da6
.L_lambda_simple_params_end_6da6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6da6
	jmp .L_lambda_simple_end_6da6
.L_lambda_simple_code_6da6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_6da6
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6da6:
	enter 0, 0
	mov rax, PARAM(2)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_27]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7748
	mov rax, L_constants + 3469

	jmp .L_if_end_7748

	.L_if_else_7748:
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_7749
	; preparing a tail-call
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2	; arg count
	mov rax, qword [free_var_120]	; free var /
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3	; arg count
	mov rax, qword [free_var_175]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 3469
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f9e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f9e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f9e
.L_tc_recycle_frame_done_8f9e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_7749

	.L_if_else_7749:
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	cmp rax, sob_boolean_false
	je .L_if_else_774a
	mov rax, L_constants + 3469

	jmp .L_if_end_774a

	.L_if_else_774a:
	; preparing a tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(2)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 3	; arg count
	mov rax, qword [free_var_175]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 3469
	push rax
	push 2	; arg count
	mov rax, qword [free_var_120]	; free var /
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8f9f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8f9f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8f9f
.L_tc_recycle_frame_done_8f9f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_774a:

	.L_if_end_7749:

	.L_if_end_7748:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_6da6:	; new closure is in rax
	mov qword [free_var_175], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_6da7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_6da7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_6da7
.L_lambda_simple_env_end_6da7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_6da7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_6da7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_6da7
.L_lambda_simple_params_end_6da7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_6da7
	jmp .L_lambda_simple_end_6da7
.L_lambda_simple_code_6da7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_6da7
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_6da7:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 3494
	push rax
	push 1	; arg count
	mov rax, qword [free_var_15]	; free var write-char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_8fa0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_8fa0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_8fa0
.L_tc_recycle_frame_done_8fa0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_6da7:	; new closure is in rax
	mov qword [free_var_176], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1

	mov rdi, rax
	call print_sexpr_if_not_void

        mov rdi, fmt_memory_usage
        mov rsi, qword [top_of_memory]
        sub rsi, memory
        mov rax, 0
        ENTER
        call printf
        LEAVE
	leave
	ret

L_error_fvar_undefined:
        push rax
        mov rdi, qword [stderr]  ; destination
        mov rsi, fmt_undefined_free_var_1
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        pop rax
        mov rax, qword [rax + 1] ; string
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rsi, 1               ; sizeof(char)
        mov rdx, qword [rax + 1] ; string-length
        mov rcx, qword [stderr]  ; destination
        mov rax, 0
        ENTER
        call fwrite
        LEAVE
        mov rdi, [stderr]       ; destination
        mov rsi, fmt_undefined_free_var_2
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -10
        call exit

L_error_non_closure:
        mov rdi, qword [stderr]
        mov rsi, fmt_non_closure
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -2
        call exit

L_error_improper_list:
	mov rdi, qword [stderr]
	mov rsi, fmt_error_improper_list
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
	mov rax, -7
	call exit

L_error_incorrect_arity_simple:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_simple
        jmp L_error_incorrect_arity_common
L_error_incorrect_arity_opt:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_opt
L_error_incorrect_arity_common:
        pop rdx
        pop rcx
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -6
        call exit

section .data
fmt_undefined_free_var_1:
        db `!!! The free variable \0`
fmt_undefined_free_var_2:
        db ` was used before it was defined.\n\0`
fmt_incorrect_arity_simple:
        db `!!! Expected %ld arguments, but given %ld\n\0`
fmt_incorrect_arity_opt:
        db `!!! Expected at least %ld arguments, but given %ld\n\0`
fmt_memory_usage:
        db `\n!!! Used %ld bytes of dynamically-allocated memory\n\n\0`
fmt_non_closure:
        db `!!! Attempting to apply a non-closure!\n\0`
fmt_error_improper_list:
	db `!!! The argument is not a proper list!\n\0`

section .bss
memory:
	resb gbytes(1)

section .data
top_of_memory:
        dq memory

section .text
malloc:
        mov rax, qword [top_of_memory]
        add qword [top_of_memory], rdi
        ret

L_code_ptr_break:
        cmp qword [rsp + 8 * 2], 0
        jne L_error_arg_count_0
        int3
        mov rax, sob_void
        ret AND_KILL_FRAME(0)        

L_code_ptr_frame:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0

        mov rdi, fmt_frame
        mov rsi, qword [rbp]    ; old rbp
        mov rdx, qword [rsi + 8*1] ; ret addr
        mov rcx, qword [rsi + 8*2] ; lexical environment
        mov r8, qword [rsi + 8*3] ; count
        lea r9, [rsi + 8*4]       ; address of argument 0
        push 0
        push r9
        push r8                   ; we'll use it when printing the params
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

.L:
        mov rcx, qword [rsp]
        cmp rcx, 0
        je .L_out
        mov rdi, fmt_frame_param_prefix
        mov rsi, qword [rsp + 8*2]
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

        mov rcx, qword [rsp]
        dec rcx
        mov qword [rsp], rcx    ; dec arg count
        inc qword [rsp + 8*2]   ; increment index of current arg
        mov rdi, qword [rsp + 8*1] ; addr of addr current arg
        lea r9, [rdi + 8]          ; addr of next arg
        mov qword [rsp + 8*1], r9  ; backup addr of next arg
        mov rdi, qword [rdi]       ; addr of current arg
        call print_sexpr
        mov rdi, fmt_newline
        mov rax, 0
        ENTER
        call printf
        LEAVE
        jmp .L
.L_out:
        mov rdi, fmt_frame_continue
        mov rax, 0
        ENTER
        call printf
        call getchar
        LEAVE
        
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(0)
        
print_sexpr_if_not_void:
	cmp rdi, sob_void
	je .done
	call print_sexpr
	mov rdi, fmt_newline
	mov rax, 0
	ENTER
	call printf
	LEAVE
.done:
	ret

section .data
fmt_frame:
        db `RBP = %p; ret addr = %p; lex env = %p; param count = %d\n\0`
fmt_frame_param_prefix:
        db `==[param %d]==> \0`
fmt_frame_continue:
        db `Hit <Enter> to continue...\0`
fmt_newline:
	db `\n\0`
fmt_void:
	db `#<void>\0`
fmt_nil:
	db `()\0`
fmt_boolean_false:
	db `#f\0`
fmt_boolean_true:
	db `#t\0`
fmt_char_backslash:
	db `#\\\\\0`
fmt_char_dquote:
	db `#\\"\0`
fmt_char_simple:
	db `#\\%c\0`
fmt_char_null:
	db `#\\nul\0`
fmt_char_bell:
	db `#\\bell\0`
fmt_char_backspace:
	db `#\\backspace\0`
fmt_char_tab:
	db `#\\tab\0`
fmt_char_newline:
	db `#\\newline\0`
fmt_char_formfeed:
	db `#\\page\0`
fmt_char_return:
	db `#\\return\0`
fmt_char_escape:
	db `#\\esc\0`
fmt_char_space:
	db `#\\space\0`
fmt_char_hex:
	db `#\\x%02X\0`
fmt_gensym:
        db `G%ld\0`
fmt_closure:
	db `#<closure at 0x%08X env=0x%08X code=0x%08X>\0`
fmt_lparen:
	db `(\0`
fmt_dotted_pair:
	db ` . \0`
fmt_rparen:
	db `)\0`
fmt_space:
	db ` \0`
fmt_empty_vector:
	db `#()\0`
fmt_vector:
	db `#(\0`
fmt_real:
	db `%f\0`
fmt_fraction:
	db `%ld/%ld\0`
fmt_zero:
	db `0\0`
fmt_int:
	db `%ld\0`
fmt_unknown_scheme_object_error:
	db `\n\n!!! Error: Unknown Scheme-object (RTTI 0x%02X) `
	db `at address 0x%08X\n\n\0`
fmt_dquote:
	db `\"\0`
fmt_string_char:
        db `%c\0`
fmt_string_char_7:
        db `\\a\0`
fmt_string_char_8:
        db `\\b\0`
fmt_string_char_9:
        db `\\t\0`
fmt_string_char_10:
        db `\\n\0`
fmt_string_char_11:
        db `\\v\0`
fmt_string_char_12:
        db `\\f\0`
fmt_string_char_13:
        db `\\r\0`
fmt_string_char_34:
        db `\\"\0`
fmt_string_char_92:
        db `\\\\\0`
fmt_string_char_hex:
        db `\\x%X;\0`

section .text

print_sexpr:
	enter 0, 0
	mov al, byte [rdi]
	cmp al, T_void
	je .Lvoid
	cmp al, T_nil
	je .Lnil
	cmp al, T_boolean_false
	je .Lboolean_false
	cmp al, T_boolean_true
	je .Lboolean_true
	cmp al, T_char
	je .Lchar
	cmp al, T_interned_symbol
	je .Linterned_symbol
        cmp al, T_uninterned_symbol
        je .Luninterned_symbol
	cmp al, T_pair
	je .Lpair
	cmp al, T_vector
	je .Lvector
	cmp al, T_closure
	je .Lclosure
	cmp al, T_real
	je .Lreal
	cmp al, T_fraction
	je .Lfraction
	cmp al, T_integer
	je .Linteger
	cmp al, T_string
	je .Lstring

	jmp .Lunknown_sexpr_type

.Lvoid:
	mov rdi, fmt_void
	jmp .Lemit

.Lnil:
	mov rdi, fmt_nil
	jmp .Lemit

.Lboolean_false:
	mov rdi, fmt_boolean_false
	jmp .Lemit

.Lboolean_true:
	mov rdi, fmt_boolean_true
	jmp .Lemit

.Lchar:
	mov al, byte [rdi + 1]
	cmp al, ' '
	jle .Lchar_whitespace
	cmp al, 92 		; backslash
	je .Lchar_backslash
	cmp al, '"'
	je .Lchar_dquote
	and rax, 255
	mov rdi, fmt_char_simple
	mov rsi, rax
	jmp .Lemit

.Lchar_whitespace:
	cmp al, 0
	je .Lchar_null
	cmp al, 7
	je .Lchar_bell
	cmp al, 8
	je .Lchar_backspace
	cmp al, 9
	je .Lchar_tab
	cmp al, 10
	je .Lchar_newline
	cmp al, 12
	je .Lchar_formfeed
	cmp al, 13
	je .Lchar_return
	cmp al, 27
	je .Lchar_escape
	and rax, 255
	cmp al, ' '
	je .Lchar_space
	mov rdi, fmt_char_hex
	mov rsi, rax
	jmp .Lemit	

.Lchar_backslash:
	mov rdi, fmt_char_backslash
	jmp .Lemit

.Lchar_dquote:
	mov rdi, fmt_char_dquote
	jmp .Lemit

.Lchar_null:
	mov rdi, fmt_char_null
	jmp .Lemit

.Lchar_bell:
	mov rdi, fmt_char_bell
	jmp .Lemit

.Lchar_backspace:
	mov rdi, fmt_char_backspace
	jmp .Lemit

.Lchar_tab:
	mov rdi, fmt_char_tab
	jmp .Lemit

.Lchar_newline:
	mov rdi, fmt_char_newline
	jmp .Lemit

.Lchar_formfeed:
	mov rdi, fmt_char_formfeed
	jmp .Lemit

.Lchar_return:
	mov rdi, fmt_char_return
	jmp .Lemit

.Lchar_escape:
	mov rdi, fmt_char_escape
	jmp .Lemit

.Lchar_space:
	mov rdi, fmt_char_space
	jmp .Lemit

.Lclosure:
	mov rsi, qword rdi
	mov rdi, fmt_closure
	mov rdx, SOB_CLOSURE_ENV(rsi)
	mov rcx, SOB_CLOSURE_CODE(rsi)
	jmp .Lemit

.Linterned_symbol:
	mov rdi, qword [rdi + 1] ; sob_string
	mov rsi, 1		 ; size = 1 byte
	mov rdx, qword [rdi + 1] ; length
	lea rdi, [rdi + 1 + 8]	 ; actual characters
	mov rcx, qword [stdout]	 ; FILE *
	ENTER
	call fwrite
	LEAVE
	jmp .Lend

.Luninterned_symbol:
        mov rsi, qword [rdi + 1] ; gensym counter
        mov rdi, fmt_gensym
        jmp .Lemit
	
.Lpair:
	push rdi
	mov rdi, fmt_lparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp] 	; pair
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi 		; pair
	mov rdi, SOB_PAIR_CDR(rdi)
.Lcdr:
	mov al, byte [rdi]
	cmp al, T_nil
	je .Lcdr_nil
	cmp al, T_pair
	je .Lcdr_pair
	push rdi
	mov rdi, fmt_dotted_pair
	mov rax, 0
        ENTER
	call printf
        LEAVE
	pop rdi
	call print_sexpr
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_nil:
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_pair:
	push rdi
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi
	mov rdi, SOB_PAIR_CDR(rdi)
	jmp .Lcdr

.Lvector:
	mov rax, qword [rdi + 1] ; length
	cmp rax, 0
	je .Lvector_empty
	push rdi
	mov rdi, fmt_vector
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	push qword [rdi + 1]
	push 1
	mov rdi, qword [rdi + 1 + 8] ; v[0]
	call print_sexpr
.Lvector_loop:
	; [rsp] index
	; [rsp + 8*1] limit
	; [rsp + 8*2] vector
	mov rax, qword [rsp]
	cmp rax, qword [rsp + 8*1]
	je .Lvector_end
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rax, qword [rsp]
	mov rbx, qword [rsp + 8*2]
	mov rdi, qword [rbx + 1 + 8 + 8 * rax] ; v[i]
	call print_sexpr
	inc qword [rsp]
	jmp .Lvector_loop

.Lvector_end:
	add rsp, 8*3
	mov rdi, fmt_rparen
	jmp .Lemit	

.Lvector_empty:
	mov rdi, fmt_empty_vector
	jmp .Lemit

.Lreal:
	push qword [rdi + 1]
	movsd xmm0, qword [rsp]
	add rsp, 8*1
	mov rdi, fmt_real
	mov rax, 1
	ENTER
	call printf
	LEAVE
	jmp .Lend

.Lfraction:
	mov rsi, qword [rdi + 1]
	mov rdx, qword [rdi + 1 + 8]
	cmp rsi, 0
	je .Lrat_zero
	cmp rdx, 1
	je .Lrat_int
	mov rdi, fmt_fraction
	jmp .Lemit

.Lrat_zero:
	mov rdi, fmt_zero
	jmp .Lemit

.Lrat_int:
	mov rdi, fmt_int
	jmp .Lemit

.Linteger:
	mov rsi, qword [rdi + 1]
	mov rdi, fmt_int
	jmp .Lemit

.Lstring:
	lea rax, [rdi + 1 + 8]
	push rax
	push qword [rdi + 1]
	mov rdi, fmt_dquote
	mov rax, 0
	ENTER
	call printf
	LEAVE
.Lstring_loop:
	; qword [rsp]: limit
	; qword [rsp + 8*1]: char *
	cmp qword [rsp], 0
	je .Lstring_end
	mov rax, qword [rsp + 8*1]
	mov al, byte [rax]
	and rax, 255
	cmp al, 7
        je .Lstring_char_7
        cmp al, 8
        je .Lstring_char_8
        cmp al, 9
        je .Lstring_char_9
        cmp al, 10
        je .Lstring_char_10
        cmp al, 11
        je .Lstring_char_11
        cmp al, 12
        je .Lstring_char_12
        cmp al, 13
        je .Lstring_char_13
        cmp al, 34
        je .Lstring_char_34
        cmp al, 92              ; \
        je .Lstring_char_92
        cmp al, ' '
        jl .Lstring_char_hex
        mov rdi, fmt_string_char
        mov rsi, rax
.Lstring_char_emit:
        mov rax, 0
        ENTER
        call printf
        LEAVE
        dec qword [rsp]
        inc qword [rsp + 8*1]
        jmp .Lstring_loop

.Lstring_char_7:
        mov rdi, fmt_string_char_7
        jmp .Lstring_char_emit

.Lstring_char_8:
        mov rdi, fmt_string_char_8
        jmp .Lstring_char_emit
        
.Lstring_char_9:
        mov rdi, fmt_string_char_9
        jmp .Lstring_char_emit

.Lstring_char_10:
        mov rdi, fmt_string_char_10
        jmp .Lstring_char_emit

.Lstring_char_11:
        mov rdi, fmt_string_char_11
        jmp .Lstring_char_emit

.Lstring_char_12:
        mov rdi, fmt_string_char_12
        jmp .Lstring_char_emit

.Lstring_char_13:
        mov rdi, fmt_string_char_13
        jmp .Lstring_char_emit

.Lstring_char_34:
        mov rdi, fmt_string_char_34
        jmp .Lstring_char_emit

.Lstring_char_92:
        mov rdi, fmt_string_char_92
        jmp .Lstring_char_emit

.Lstring_char_hex:
        mov rdi, fmt_string_char_hex
        mov rsi, rax
        jmp .Lstring_char_emit        

.Lstring_end:
	add rsp, 8 * 2
	mov rdi, fmt_dquote
	jmp .Lemit

.Lunknown_sexpr_type:
	mov rsi, fmt_unknown_scheme_object_error
	and rax, 255
	mov rdx, rax
	mov rcx, rdi
	mov rdi, qword [stderr]
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
        leave
        ret

.Lemit:
	mov rax, 0
        ENTER
	call printf
        LEAVE
	jmp .Lend

.Lend:
	LEAVE
	ret

;;; rdi: address of free variable
;;; rsi: address of code-pointer
bind_primitive:
        enter 0, 0
        push rdi
        mov rdi, (1 + 8 + 8)
        call malloc
        pop rdi
        mov byte [rax], T_closure
        mov SOB_CLOSURE_ENV(rax), 0 ; dummy, lexical environment
        mov SOB_CLOSURE_CODE(rax), rsi ; code pointer
        mov qword [rdi], rax
        mov rax, sob_void
        leave
        ret

L_code_ptr_ash:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_integer(rdi)
        mov rcx, PARAM(1)
        assert_integer(rcx)
        mov rdi, qword [rdi + 1]
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl .L_negative
.L_loop_positive:
        cmp rcx, 0
        je .L_exit
        sal rdi, cl
        shr rcx, 8
        jmp .L_loop_positive
.L_negative:
        neg rcx
.L_loop_negative:
        cmp rcx, 0
        je .L_exit
        sar rdi, cl
        shr rcx, 8
        jmp .L_loop_negative
.L_exit:
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logand:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        and rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        or rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logxor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        xor rdi, qword [r9 + 1]
        call make_integer
        LEAVE
        ret AND_KILL_FRAME(2)

L_code_ptr_lognot:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, qword [r8 + 1]
        not rdi
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_bin_apply:
        cmp qword [rsp + 8 * 2], 2
        jne L_error_arg_count_2
        mov r12, qword [rsp + 8 * 3]
        assert_closure(r12)
        lea r10, [rsp + 8 * 4]
        mov r11, qword [r10]
        mov r9, qword [rsp]
        mov rcx, 0
        mov rsi, r11
.L0:
        cmp rsi, sob_nil
        je .L0_out
        assert_pair(rsi)
        inc rcx
        mov rsi, SOB_PAIR_CDR(rsi)
        jmp .L0
.L0_out:
        lea rbx, [8 * (rcx - 2)]
        sub rsp, rbx
        mov rdi, rsp
        cld
        ; place ret addr
        mov rax, r9
        stosq
        ; place env_f
        mov rax, SOB_CLOSURE_ENV(r12)
        stosq
        ; place COUNT = rcx
        mov rax, rcx
        stosq
.L1:
        cmp rcx, 0
        je .L1_out
        mov rax, SOB_PAIR_CAR(r11)
        stosq
        mov r11, SOB_PAIR_CDR(r11)
        dec rcx
        jmp .L1
.L1_out:
        sub rdi, 8*1
        cmp r10, rdi
        jne .L_error_apply_stack_corrupted
        jmp SOB_CLOSURE_CODE(r12)
.L_error_apply_stack_corrupted:
        int3

L_code_ptr_is_null:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_nil
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_pair:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_pair
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_void:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_void
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_char
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_string:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_string
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        and byte [r8], T_symbol
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_uninterned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        cmp byte [r8], T_uninterned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_interned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_interned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_gensym:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        inc qword [gensym_count]
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_uninterned_symbol
        mov rcx, qword [gensym_count]
        mov qword [rax + 1], rcx
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_vector:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_vector
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_closure:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_closure
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_real
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_fraction
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_boolean
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_boolean_false:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_false
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean_true:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_true
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_number:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_number
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_collection:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_collection
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_cons:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_pair
        mov rbx, PARAM(0)
        mov SOB_PAIR_CAR(rax), rbx
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_display_sexpr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rdi, PARAM(0)
        call print_sexpr
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_write_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, SOB_CHAR_VALUE(rax)
        and rax, 255
        mov rdi, fmt_char
        mov rsi, rax
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_car:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CAR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_cdr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CDR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_string_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_string(rax)
        mov rdi, SOB_STRING_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_vector_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_vector(rax)
        mov rdi, SOB_VECTOR_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_real_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rbx, PARAM(0)
        assert_real(rbx)
        movsd xmm0, qword [rbx + 1]
        cvttsd2si rdi, xmm0
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_exit:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        mov rax, 0
        call exit

L_code_ptr_integer_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_fraction_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        push qword [rax + 1 + 8]
        cvtsi2sd xmm1, qword [rsp]
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_char_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, byte [rax + 1]
        and rax, 255
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, (1 + 8 + 8)
        call malloc
        mov rbx, qword [r8 + 1]
        mov byte [rax], T_fraction
        mov qword [rax + 1], rbx
        mov qword [rax + 1 + 8], 1
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        mov rbx, qword [rax + 1]
        cmp rbx, 0
        jle L_error_integer_range
        cmp rbx, 256
        jge L_error_integer_range
        mov rdi, (1 + 1)
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_trng:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        rdrand rdi
        shr rdi, 1
        call make_integer
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_zero:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        je .L_integer
        cmp byte [rax], T_fraction
        je .L_fraction
        cmp byte [rax], T_real
        je .L_real
        jmp L_error_incorrect_type
.L_integer:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_fraction:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_real:
        pxor xmm0, xmm0
        push qword [rax + 1]
        movsd xmm1, qword [rsp]
        ucomisd xmm0, xmm1
        je .L_zero
.L_not_zero:
        mov rax, sob_boolean_false
        jmp .L_end
.L_zero:
        mov rax, sob_boolean_true
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_raw_bin_add_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        addsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        subsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        mulsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        pxor xmm2, xmm2
        ucomisd xmm1, xmm2
        je L_error_division_by_zero
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_add_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	add rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)
	
L_code_ptr_raw_bin_add_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        add rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	sub rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        sub rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	cqo
	mov rax, qword [r8 + 1]
	mul qword [r9 + 1]
	mov rdi, rax
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_bin_div_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r9 + 1]
	cmp rdi, 0
	je L_error_division_by_zero
	mov rsi, qword [r8 + 1]
	call normalize_fraction
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        cmp qword [r9 + 1], 0
        je L_error_division_by_zero
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
normalize_fraction:
        push rsi
        push rdi
        call gcd
        mov rbx, rax
        pop rax
        cqo
        idiv rbx
        mov r8, rax
        pop rax
        cqo
        idiv rbx
        mov r9, rax
        cmp r9, 0
        je .L_zero
        cmp r8, 1
        je .L_int
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_fraction
        mov qword [rax + 1], r9
        mov qword [rax + 1 + 8], r8
        ret
.L_zero:
        mov rdi, 0
        call make_integer
        ret
.L_int:
        mov rdi, r9
        call make_integer
        ret

iabs:
        mov rax, rdi
        cmp rax, 0
        jl .Lneg
        ret
.Lneg:
        neg rax
        ret

gcd:
        call iabs
        mov rbx, rax
        mov rdi, rsi
        call iabs
        cmp rax, 0
        jne .L0
        xchg rax, rbx
.L0:
        cmp rbx, 0
        je .L1
        cqo
        div rbx
        mov rax, rdx
        xchg rax, rbx
        jmp .L0
.L1:
        ret

L_code_ptr_error:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_interned_symbol(rsi)
        mov rsi, PARAM(1)
        assert_string(rsi)
        mov rdi, fmt_scheme_error_part_1
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rdi, PARAM(0)
        call print_sexpr
        mov rdi, fmt_scheme_error_part_2
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, PARAM(1)       ; sob_string
        mov rsi, 1              ; size = 1 byte
        mov rdx, qword [rax + 1] ; length
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rcx, qword [stdout]  ; FILE*
	ENTER
        call fwrite
	LEAVE
        mov rdi, fmt_scheme_error_part_3
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, -9
        call exit

L_code_ptr_raw_less_than_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jae .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_less_than_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jge .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_less_than_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rsi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jge .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_equal_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jne .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rdi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_quotient:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_remainder:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rdx
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_car:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CAR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_cdr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_string_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov bl, byte [rdi + 1 + 8 + 1 * rcx]
        mov rdi, 2
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, [rdi + 1 + 8 + 8 * rcx]
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        mov qword [rdi + 1 + 8 + 8 * rcx], rax
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_string_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        assert_char(rax)
        mov al, byte [rax + 1]
        mov byte [rdi + 1 + 8 + 1 * rcx], al
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_make_vector:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        lea rdi, [1 + 8 + 8 * rcx]
        call malloc
        mov byte [rax], T_vector
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov qword [rax + 1 + 8 + 8 * r8], rdx
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_make_string:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        assert_char(rdx)
        mov dl, byte [rdx + 1]
        lea rdi, [1 + 8 + 1 * rcx]
        call malloc
        mov byte [rax], T_string
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov byte [rax + 1 + 8 + 1 * r8], dl
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_numerator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_denominator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1 + 8]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_eq:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov rdi, PARAM(0)
	mov rsi, PARAM(1)
	cmp rdi, rsi
	je .L_eq_true
	mov dl, byte [rdi]
	cmp dl, byte [rsi]
	jne .L_eq_false
	cmp dl, T_char
	je .L_char
	cmp dl, T_interned_symbol
	je .L_interned_symbol
        cmp dl, T_uninterned_symbol
        je .L_uninterned_symbol
	cmp dl, T_real
	je .L_real
	cmp dl, T_fraction
	je .L_fraction
	jmp .L_eq_false
.L_fraction:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
	jne .L_eq_false
	mov rax, qword [rsi + 1 + 8]
	cmp rax, qword [rdi + 1 + 8]
	jne .L_eq_false
	jmp .L_eq_true
.L_real:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_interned_symbol:
	; never reached, because interned_symbols are static!
	; but I'm keeping it in case, I'll ever change
	; the implementation
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_uninterned_symbol:
        mov r8, qword [rdi + 1]
        cmp r8, qword [rsi + 1]
        jne .L_eq_false
        jmp .L_eq_true
.L_char:
	mov bl, byte [rsi + 1]
	cmp bl, byte [rdi + 1]
	jne .L_eq_false
.L_eq_true:
	mov rax, sob_boolean_true
	jmp .L_eq_exit
.L_eq_false:
	mov rax, sob_boolean_false
.L_eq_exit:
	leave
	ret AND_KILL_FRAME(2)

make_real:
        enter 0, 0
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_real
        movsd qword [rax + 1], xmm0
        leave 
        ret
        
make_integer:
        enter 0, 0
        mov rsi, rdi
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_integer
        mov qword [rax + 1], rsi
        leave
        ret
        
L_error_integer_range:
        mov rdi, qword [stderr]
        mov rsi, fmt_integer_range
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -5
        call exit

L_error_arg_count_0:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_0
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_1:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_1
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_2:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_2
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_12:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_12
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_3:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_3
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit
        
L_error_incorrect_type:
        mov rdi, qword [stderr]
        mov rsi, fmt_type
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -4
        call exit

L_error_division_by_zero:
        mov rdi, qword [stderr]
        mov rsi, fmt_division_by_zero
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -8
        call exit

section .data
gensym_count:
        dq 0
fmt_char:
        db `%c\0`
fmt_arg_count_0:
        db `!!! Expecting zero arguments. Found %d\n\0`
fmt_arg_count_1:
        db `!!! Expecting one argument. Found %d\n\0`
fmt_arg_count_12:
        db `!!! Expecting one required and one optional argument. Found %d\n\0`
fmt_arg_count_2:
        db `!!! Expecting two arguments. Found %d\n\0`
fmt_arg_count_3:
        db `!!! Expecting three arguments. Found %d\n\0`
fmt_type:
        db `!!! Function passed incorrect type\n\0`
fmt_integer_range:
        db `!!! Incorrect integer range\n\0`
fmt_division_by_zero:
        db `!!! Division by zero\n\0`
fmt_scheme_error_part_1:
        db `\n!!! The procedure \0`
fmt_scheme_error_part_2:
        db ` asked to terminate the program\n`
        db `    with the following message:\n\n\0`
fmt_scheme_error_part_3:
        db `\n\nGoodbye!\n\n\0`