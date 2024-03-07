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
	; L_constants + 3496:
	db T_string	; "a"
	dq 1
	db 0x61
	; L_constants + 3506:
	db T_interned_symbol	; a
	dq L_constants + 3496
	; L_constants + 3515:
	db T_pair	; (a)
	dq L_constants + 3506, L_constants + 1
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
.L_lambda_simple_env_loop_0525:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0525
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0525
.L_lambda_simple_env_end_0525:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0525:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0525
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0525
.L_lambda_simple_params_end_0525:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0525
	jmp .L_lambda_simple_end_0525
.L_lambda_simple_code_0525:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0525
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0525:
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
.L_tc_recycle_frame_loop_06c2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06c2
.L_tc_recycle_frame_done_06c2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0525:	; new closure is in rax
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
.L_lambda_simple_env_loop_0526:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0526
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0526
.L_lambda_simple_env_end_0526:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0526:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0526
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0526
.L_lambda_simple_params_end_0526:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0526
	jmp .L_lambda_simple_end_0526
.L_lambda_simple_code_0526:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0526
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0526:
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
.L_tc_recycle_frame_loop_06c3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06c3
.L_tc_recycle_frame_done_06c3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0526:	; new closure is in rax
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
.L_lambda_simple_env_loop_0527:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0527
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0527
.L_lambda_simple_env_end_0527:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0527:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0527
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0527
.L_lambda_simple_params_end_0527:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0527
	jmp .L_lambda_simple_end_0527
.L_lambda_simple_code_0527:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0527
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0527:
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
.L_tc_recycle_frame_loop_06c4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06c4
.L_tc_recycle_frame_done_06c4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0527:	; new closure is in rax
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
.L_lambda_simple_env_loop_0528:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0528
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0528
.L_lambda_simple_env_end_0528:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0528:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0528
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0528
.L_lambda_simple_params_end_0528:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0528
	jmp .L_lambda_simple_end_0528
.L_lambda_simple_code_0528:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0528
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0528:
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
.L_tc_recycle_frame_loop_06c5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06c5
.L_tc_recycle_frame_done_06c5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0528:	; new closure is in rax
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
.L_lambda_simple_env_loop_0529:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0529
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0529
.L_lambda_simple_env_end_0529:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0529:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0529
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0529
.L_lambda_simple_params_end_0529:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0529
	jmp .L_lambda_simple_end_0529
.L_lambda_simple_code_0529:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0529
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0529:
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
.L_tc_recycle_frame_loop_06c6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06c6
.L_tc_recycle_frame_done_06c6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0529:	; new closure is in rax
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
.L_lambda_simple_env_loop_052a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_052a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_052a
.L_lambda_simple_env_end_052a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_052a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_052a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_052a
.L_lambda_simple_params_end_052a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_052a
	jmp .L_lambda_simple_end_052a
.L_lambda_simple_code_052a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_052a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052a:
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
.L_tc_recycle_frame_loop_06c7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06c7
.L_tc_recycle_frame_done_06c7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_052a:	; new closure is in rax
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
.L_lambda_simple_env_loop_052b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_052b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_052b
.L_lambda_simple_env_end_052b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_052b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_052b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_052b
.L_lambda_simple_params_end_052b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_052b
	jmp .L_lambda_simple_end_052b
.L_lambda_simple_code_052b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_052b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052b:
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
.L_tc_recycle_frame_loop_06c8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06c8
.L_tc_recycle_frame_done_06c8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_052b:	; new closure is in rax
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
.L_lambda_simple_env_loop_052c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_052c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_052c
.L_lambda_simple_env_end_052c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_052c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_052c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_052c
.L_lambda_simple_params_end_052c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_052c
	jmp .L_lambda_simple_end_052c
.L_lambda_simple_code_052c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_052c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052c:
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
.L_tc_recycle_frame_loop_06c9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06c9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06c9
.L_tc_recycle_frame_done_06c9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_052c:	; new closure is in rax
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
.L_lambda_simple_env_loop_052d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_052d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_052d
.L_lambda_simple_env_end_052d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_052d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_052d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_052d
.L_lambda_simple_params_end_052d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_052d
	jmp .L_lambda_simple_end_052d
.L_lambda_simple_code_052d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_052d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052d:
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
.L_tc_recycle_frame_loop_06ca:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ca
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06ca
.L_tc_recycle_frame_done_06ca:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_052d:	; new closure is in rax
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
.L_lambda_simple_env_loop_052e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_052e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_052e
.L_lambda_simple_env_end_052e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_052e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_052e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_052e
.L_lambda_simple_params_end_052e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_052e
	jmp .L_lambda_simple_end_052e
.L_lambda_simple_code_052e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_052e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052e:
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
.L_tc_recycle_frame_loop_06cb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06cb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06cb
.L_tc_recycle_frame_done_06cb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_052e:	; new closure is in rax
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
.L_lambda_simple_env_loop_052f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_052f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_052f
.L_lambda_simple_env_end_052f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_052f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_052f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_052f
.L_lambda_simple_params_end_052f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_052f
	jmp .L_lambda_simple_end_052f
.L_lambda_simple_code_052f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_052f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052f:
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
.L_tc_recycle_frame_loop_06cc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06cc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06cc
.L_tc_recycle_frame_done_06cc:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_052f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0530:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0530
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0530
.L_lambda_simple_env_end_0530:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0530:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0530
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0530
.L_lambda_simple_params_end_0530:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0530
	jmp .L_lambda_simple_end_0530
.L_lambda_simple_code_0530:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0530
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0530:
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
.L_tc_recycle_frame_loop_06cd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06cd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06cd
.L_tc_recycle_frame_done_06cd:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0530:	; new closure is in rax
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
.L_lambda_simple_env_loop_0531:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0531
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0531
.L_lambda_simple_env_end_0531:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0531:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0531
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0531
.L_lambda_simple_params_end_0531:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0531
	jmp .L_lambda_simple_end_0531
.L_lambda_simple_code_0531:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0531
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0531:
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
.L_tc_recycle_frame_loop_06ce:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ce
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06ce
.L_tc_recycle_frame_done_06ce:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0531:	; new closure is in rax
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
.L_lambda_simple_env_loop_0532:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0532
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0532
.L_lambda_simple_env_end_0532:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0532:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0532
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0532
.L_lambda_simple_params_end_0532:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0532
	jmp .L_lambda_simple_end_0532
.L_lambda_simple_code_0532:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0532
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0532:
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
.L_tc_recycle_frame_loop_06cf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06cf
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06cf
.L_tc_recycle_frame_done_06cf:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0532:	; new closure is in rax
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
.L_lambda_simple_env_loop_0533:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0533
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0533
.L_lambda_simple_env_end_0533:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0533:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0533
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0533
.L_lambda_simple_params_end_0533:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0533
	jmp .L_lambda_simple_end_0533
.L_lambda_simple_code_0533:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0533
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0533:
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
.L_tc_recycle_frame_loop_06d0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06d0
.L_tc_recycle_frame_done_06d0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0533:	; new closure is in rax
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
.L_lambda_simple_env_loop_0534:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0534
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0534
.L_lambda_simple_env_end_0534:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0534:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0534
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0534
.L_lambda_simple_params_end_0534:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0534
	jmp .L_lambda_simple_end_0534
.L_lambda_simple_code_0534:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0534
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0534:
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
.L_tc_recycle_frame_loop_06d1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06d1
.L_tc_recycle_frame_done_06d1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0534:	; new closure is in rax
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
.L_lambda_simple_env_loop_0535:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0535
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0535
.L_lambda_simple_env_end_0535:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0535:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0535
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0535
.L_lambda_simple_params_end_0535:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0535
	jmp .L_lambda_simple_end_0535
.L_lambda_simple_code_0535:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0535
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0535:
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
.L_tc_recycle_frame_loop_06d2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06d2
.L_tc_recycle_frame_done_06d2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0535:	; new closure is in rax
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
.L_lambda_simple_env_loop_0536:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0536
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0536
.L_lambda_simple_env_end_0536:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0536:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0536
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0536
.L_lambda_simple_params_end_0536:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0536
	jmp .L_lambda_simple_end_0536
.L_lambda_simple_code_0536:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0536
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0536:
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
.L_tc_recycle_frame_loop_06d3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06d3
.L_tc_recycle_frame_done_06d3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0536:	; new closure is in rax
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
.L_lambda_simple_env_loop_0537:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0537
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0537
.L_lambda_simple_env_end_0537:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0537:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0537
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0537
.L_lambda_simple_params_end_0537:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0537
	jmp .L_lambda_simple_end_0537
.L_lambda_simple_code_0537:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0537
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0537:
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
.L_tc_recycle_frame_loop_06d4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06d4
.L_tc_recycle_frame_done_06d4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0537:	; new closure is in rax
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
.L_lambda_simple_env_loop_0538:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0538
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0538
.L_lambda_simple_env_end_0538:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0538:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0538
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0538
.L_lambda_simple_params_end_0538:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0538
	jmp .L_lambda_simple_end_0538
.L_lambda_simple_code_0538:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0538
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0538:
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
.L_tc_recycle_frame_loop_06d5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06d5
.L_tc_recycle_frame_done_06d5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0538:	; new closure is in rax
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
.L_lambda_simple_env_loop_0539:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0539
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0539
.L_lambda_simple_env_end_0539:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0539:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0539
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0539
.L_lambda_simple_params_end_0539:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0539
	jmp .L_lambda_simple_end_0539
.L_lambda_simple_code_0539:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0539
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0539:
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
.L_tc_recycle_frame_loop_06d6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06d6
.L_tc_recycle_frame_done_06d6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0539:	; new closure is in rax
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
.L_lambda_simple_env_loop_053a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_053a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_053a
.L_lambda_simple_env_end_053a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_053a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_053a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_053a
.L_lambda_simple_params_end_053a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_053a
	jmp .L_lambda_simple_end_053a
.L_lambda_simple_code_053a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_053a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053a:
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
.L_tc_recycle_frame_loop_06d7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06d7
.L_tc_recycle_frame_done_06d7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_053a:	; new closure is in rax
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
.L_lambda_simple_env_loop_053b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_053b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_053b
.L_lambda_simple_env_end_053b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_053b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_053b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_053b
.L_lambda_simple_params_end_053b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_053b
	jmp .L_lambda_simple_end_053b
.L_lambda_simple_code_053b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_053b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053b:
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
.L_tc_recycle_frame_loop_06d8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06d8
.L_tc_recycle_frame_done_06d8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_053b:	; new closure is in rax
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
.L_lambda_simple_env_loop_053c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_053c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_053c
.L_lambda_simple_env_end_053c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_053c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_053c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_053c
.L_lambda_simple_params_end_053c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_053c
	jmp .L_lambda_simple_end_053c
.L_lambda_simple_code_053c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_053c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053c:
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
.L_tc_recycle_frame_loop_06d9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06d9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06d9
.L_tc_recycle_frame_done_06d9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_053c:	; new closure is in rax
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
.L_lambda_simple_env_loop_053d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_053d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_053d
.L_lambda_simple_env_end_053d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_053d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_053d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_053d
.L_lambda_simple_params_end_053d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_053d
	jmp .L_lambda_simple_end_053d
.L_lambda_simple_code_053d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_053d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053d:
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
.L_tc_recycle_frame_loop_06da:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06da
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06da
.L_tc_recycle_frame_done_06da:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_053d:	; new closure is in rax
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
.L_lambda_simple_env_loop_053e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_053e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_053e
.L_lambda_simple_env_end_053e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_053e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_053e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_053e
.L_lambda_simple_params_end_053e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_053e
	jmp .L_lambda_simple_end_053e
.L_lambda_simple_code_053e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_053e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053e:
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
.L_tc_recycle_frame_loop_06db:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06db
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06db
.L_tc_recycle_frame_done_06db:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_053e:	; new closure is in rax
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
.L_lambda_simple_env_loop_053f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_053f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_053f
.L_lambda_simple_env_end_053f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_053f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_053f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_053f
.L_lambda_simple_params_end_053f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_053f
	jmp .L_lambda_simple_end_053f
.L_lambda_simple_code_053f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_053f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053f:
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
.L_tc_recycle_frame_loop_06dc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06dc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06dc
.L_tc_recycle_frame_done_06dc:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_053f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0540:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0540
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0540
.L_lambda_simple_env_end_0540:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0540:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0540
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0540
.L_lambda_simple_params_end_0540:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0540
	jmp .L_lambda_simple_end_0540
.L_lambda_simple_code_0540:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0540
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0540:
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
.L_tc_recycle_frame_loop_06dd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06dd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06dd
.L_tc_recycle_frame_done_06dd:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0540:	; new closure is in rax
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
.L_lambda_simple_env_loop_0541:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0541
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0541
.L_lambda_simple_env_end_0541:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0541:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0541
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0541
.L_lambda_simple_params_end_0541:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0541
	jmp .L_lambda_simple_end_0541
.L_lambda_simple_code_0541:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0541
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0541:
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
	jne .L_or_end_005c
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
	je .L_if_else_03ce
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
.L_tc_recycle_frame_loop_06de:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06de
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06de
.L_tc_recycle_frame_done_06de:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03ce

	.L_if_else_03ce:
	mov rax, L_constants + 2

	.L_if_end_03ce:
.L_or_end_005c:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0541:	; new closure is in rax
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
.L_lambda_opt_env_loop_00b0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_00b0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b0
.L_lambda_opt_env_end_00b0:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b0:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_00b0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b0
.L_lambda_opt_params_end_00b0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b0
	jmp .L_lambda_opt_end_00b0
.L_lambda_opt_code_00b0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00b0 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00b0 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00b0:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00b0:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00b0
	.L_lambda_opt_exact_shifting_loop_end_00b0:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00b0
	.L_lambda_opt_arity_check_more_00b0:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00b0
	.L_lambda_opt_stack_shrink_loop_00b0:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00b0:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00b0
	.L_lambda_opt_more_shifting_loop_end_00b0:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_00b0
	.L_lambda_opt_stack_shrink_loop_exit_00b0:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00b0:
	enter 0, 0
	mov rax, PARAM(0)	; param args
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00b0:	; new closure is in rax
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
.L_lambda_simple_env_loop_0542:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0542
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0542
.L_lambda_simple_env_end_0542:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0542:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0542
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0542
.L_lambda_simple_params_end_0542:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0542
	jmp .L_lambda_simple_end_0542
.L_lambda_simple_code_0542:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0542
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0542:
	enter 0, 0
	mov rax, PARAM(0)	; param x

	cmp rax, sob_boolean_false
	je .L_if_else_03cf
	mov rax, L_constants + 2

	jmp .L_if_end_03cf

	.L_if_else_03cf:
	mov rax, L_constants + 3

	.L_if_end_03cf:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0542:	; new closure is in rax
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
.L_lambda_simple_env_loop_0543:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0543
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0543
.L_lambda_simple_env_end_0543:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0543:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0543
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0543
.L_lambda_simple_params_end_0543:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0543
	jmp .L_lambda_simple_end_0543
.L_lambda_simple_code_0543:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0543
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0543:
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
	jne .L_or_end_005d
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
.L_tc_recycle_frame_loop_06df:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06df
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06df
.L_tc_recycle_frame_done_06df:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_005d:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0543:	; new closure is in rax
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
.L_lambda_simple_env_loop_0544:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0544
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0544
.L_lambda_simple_env_end_0544:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0544:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0544
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0544
.L_lambda_simple_params_end_0544:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0544
	jmp .L_lambda_simple_end_0544
.L_lambda_simple_code_0544:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0544
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0544:
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
.L_lambda_simple_env_loop_0545:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0545
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0545
.L_lambda_simple_env_end_0545:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0545:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0545
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0545
.L_lambda_simple_params_end_0545:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0545
	jmp .L_lambda_simple_end_0545
.L_lambda_simple_code_0545:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0545
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0545:
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
	je .L_if_else_03d0
	mov rax, PARAM(0)	; param a

	jmp .L_if_end_03d0

	.L_if_else_03d0:
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
.L_tc_recycle_frame_loop_06e0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06e0
.L_tc_recycle_frame_done_06e0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03d0:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0545:	; new closure is in rax

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
.L_lambda_opt_env_loop_00b1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00b1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b1
.L_lambda_opt_env_end_00b1:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b1:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00b1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b1
.L_lambda_opt_params_end_00b1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b1
	jmp .L_lambda_opt_end_00b1
.L_lambda_opt_code_00b1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00b1 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00b1 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00b1:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00b1:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00b1
	.L_lambda_opt_exact_shifting_loop_end_00b1:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00b1
	.L_lambda_opt_arity_check_more_00b1:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00b1
	.L_lambda_opt_stack_shrink_loop_00b1:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00b1:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00b1
	.L_lambda_opt_more_shifting_loop_end_00b1:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_00b1
	.L_lambda_opt_stack_shrink_loop_exit_00b1:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00b1:
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
.L_tc_recycle_frame_loop_06e1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06e1
.L_tc_recycle_frame_done_06e1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00b1:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0544:	; new closure is in rax
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
.L_lambda_simple_env_loop_0546:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0546
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0546
.L_lambda_simple_env_end_0546:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0546:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0546
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0546
.L_lambda_simple_params_end_0546:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0546
	jmp .L_lambda_simple_end_0546
.L_lambda_simple_code_0546:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0546
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0546:
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
.L_lambda_simple_env_loop_0547:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0547
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0547
.L_lambda_simple_env_end_0547:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0547:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0547
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0547
.L_lambda_simple_params_end_0547:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0547
	jmp .L_lambda_simple_end_0547
.L_lambda_simple_code_0547:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0547
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0547:
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
	je .L_if_else_03d1
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
.L_tc_recycle_frame_loop_06e2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06e2
.L_tc_recycle_frame_done_06e2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03d1

	.L_if_else_03d1:
	mov rax, PARAM(0)	; param a

	.L_if_end_03d1:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0547:	; new closure is in rax

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
.L_lambda_opt_env_loop_00b2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00b2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b2
.L_lambda_opt_env_end_00b2:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b2:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00b2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b2
.L_lambda_opt_params_end_00b2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b2
	jmp .L_lambda_opt_end_00b2
.L_lambda_opt_code_00b2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00b2 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00b2 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00b2:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00b2:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00b2
	.L_lambda_opt_exact_shifting_loop_end_00b2:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00b2
	.L_lambda_opt_arity_check_more_00b2:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00b2
	.L_lambda_opt_stack_shrink_loop_00b2:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00b2:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00b2
	.L_lambda_opt_more_shifting_loop_end_00b2:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_00b2
	.L_lambda_opt_stack_shrink_loop_exit_00b2:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00b2:
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
.L_tc_recycle_frame_loop_06e3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06e3
.L_tc_recycle_frame_done_06e3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00b2:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0546:	; new closure is in rax
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
.L_lambda_opt_env_loop_00b3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_00b3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b3
.L_lambda_opt_env_end_00b3:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b3:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_00b3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b3
.L_lambda_opt_params_end_00b3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b3
	jmp .L_lambda_opt_end_00b3
.L_lambda_opt_code_00b3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00b3 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00b3 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00b3:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00b3:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00b3
	.L_lambda_opt_exact_shifting_loop_end_00b3:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00b3
	.L_lambda_opt_arity_check_more_00b3:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00b3
	.L_lambda_opt_stack_shrink_loop_00b3:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00b3:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00b3
	.L_lambda_opt_more_shifting_loop_end_00b3:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_00b3
	.L_lambda_opt_stack_shrink_loop_exit_00b3:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00b3:
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
.L_lambda_simple_env_loop_0548:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0548
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0548
.L_lambda_simple_env_end_0548:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0548:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0548
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0548
.L_lambda_simple_params_end_0548:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0548
	jmp .L_lambda_simple_end_0548
.L_lambda_simple_code_0548:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0548
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0548:
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
.L_lambda_simple_env_loop_0549:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0549
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0549
.L_lambda_simple_env_end_0549:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0549:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0549
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0549
.L_lambda_simple_params_end_0549:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0549
	jmp .L_lambda_simple_end_0549
.L_lambda_simple_code_0549:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0549
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0549:
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
	je .L_if_else_03d2
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
	jne .L_or_end_005e
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
.L_tc_recycle_frame_loop_06e4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06e4
.L_tc_recycle_frame_done_06e4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_005e:

	jmp .L_if_end_03d2

	.L_if_else_03d2:
	mov rax, L_constants + 2

	.L_if_end_03d2:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0549:	; new closure is in rax

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
.L_tc_recycle_frame_loop_06e5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06e5
.L_tc_recycle_frame_done_06e5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0548:	; new closure is in rax
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
.L_tc_recycle_frame_loop_06e6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06e6
.L_tc_recycle_frame_done_06e6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00b3:	; new closure is in rax
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
.L_lambda_opt_env_loop_00b4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_00b4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b4
.L_lambda_opt_env_end_00b4:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b4:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_00b4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b4
.L_lambda_opt_params_end_00b4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b4
	jmp .L_lambda_opt_end_00b4
.L_lambda_opt_code_00b4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00b4 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00b4 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00b4:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00b4:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00b4
	.L_lambda_opt_exact_shifting_loop_end_00b4:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00b4
	.L_lambda_opt_arity_check_more_00b4:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00b4
	.L_lambda_opt_stack_shrink_loop_00b4:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00b4:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00b4
	.L_lambda_opt_more_shifting_loop_end_00b4:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_00b4
	.L_lambda_opt_stack_shrink_loop_exit_00b4:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00b4:
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
.L_lambda_simple_env_loop_054a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_054a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_054a
.L_lambda_simple_env_end_054a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_054a:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_054a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_054a
.L_lambda_simple_params_end_054a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_054a
	jmp .L_lambda_simple_end_054a
.L_lambda_simple_code_054a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_054a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054a:
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
.L_lambda_simple_env_loop_054b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_054b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_054b
.L_lambda_simple_env_end_054b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_054b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_054b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_054b
.L_lambda_simple_params_end_054b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_054b
	jmp .L_lambda_simple_end_054b
.L_lambda_simple_code_054b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_054b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054b:
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
	jne .L_or_end_005f
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
	je .L_if_else_03d3
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
.L_tc_recycle_frame_loop_06e7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06e7
.L_tc_recycle_frame_done_06e7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03d3

	.L_if_else_03d3:
	mov rax, L_constants + 2

	.L_if_end_03d3:
.L_or_end_005f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_054b:	; new closure is in rax

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
.L_tc_recycle_frame_loop_06e8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06e8
.L_tc_recycle_frame_done_06e8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_054a:	; new closure is in rax
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
.L_tc_recycle_frame_loop_06e9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06e9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06e9
.L_tc_recycle_frame_done_06e9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00b4:	; new closure is in rax
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
.L_lambda_simple_env_loop_054c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_054c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_054c
.L_lambda_simple_env_end_054c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_054c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_054c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_054c
.L_lambda_simple_params_end_054c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_054c
	jmp .L_lambda_simple_end_054c
.L_lambda_simple_code_054c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_054c
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054c:
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
.L_lambda_simple_env_loop_054d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_054d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_054d
.L_lambda_simple_env_end_054d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_054d:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_054d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_054d
.L_lambda_simple_params_end_054d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_054d
	jmp .L_lambda_simple_end_054d
.L_lambda_simple_code_054d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_054d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054d:
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
	je .L_if_else_03d4
	mov rax, L_constants + 1

	jmp .L_if_end_03d4

	.L_if_else_03d4:
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
.L_tc_recycle_frame_loop_06ea:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ea
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06ea
.L_tc_recycle_frame_done_06ea:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03d4:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_054d:	; new closure is in rax

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
.L_lambda_simple_env_loop_054e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_054e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_054e
.L_lambda_simple_env_end_054e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_054e:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_054e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_054e
.L_lambda_simple_params_end_054e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_054e
	jmp .L_lambda_simple_end_054e
.L_lambda_simple_code_054e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_054e
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054e:
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
	je .L_if_else_03d5
	mov rax, L_constants + 1

	jmp .L_if_end_03d5

	.L_if_else_03d5:
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
.L_tc_recycle_frame_loop_06eb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06eb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06eb
.L_tc_recycle_frame_done_06eb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03d5:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_054e:	; new closure is in rax

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
.L_lambda_opt_env_loop_00b5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00b5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b5
.L_lambda_opt_env_end_00b5:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b5:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_00b5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b5
.L_lambda_opt_params_end_00b5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b5
	jmp .L_lambda_opt_end_00b5
.L_lambda_opt_code_00b5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00b5 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00b5 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00b5:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00b5:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00b5
	.L_lambda_opt_exact_shifting_loop_end_00b5:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00b5
	.L_lambda_opt_arity_check_more_00b5:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00b5
	.L_lambda_opt_stack_shrink_loop_00b5:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00b5:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00b5
	.L_lambda_opt_more_shifting_loop_end_00b5:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_00b5
	.L_lambda_opt_stack_shrink_loop_exit_00b5:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00b5:
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
	je .L_if_else_03d6
	mov rax, L_constants + 1

	jmp .L_if_end_03d6

	.L_if_else_03d6:
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
.L_tc_recycle_frame_loop_06ec:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ec
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06ec
.L_tc_recycle_frame_done_06ec:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03d6:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00b5:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_054c:	; new closure is in rax
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
.L_lambda_simple_env_loop_054f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_054f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_054f
.L_lambda_simple_env_end_054f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_054f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_054f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_054f
.L_lambda_simple_params_end_054f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_054f
	jmp .L_lambda_simple_end_054f
.L_lambda_simple_code_054f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_054f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054f:
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
.L_lambda_simple_env_loop_0550:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0550
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0550
.L_lambda_simple_env_end_0550:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0550:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0550
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0550
.L_lambda_simple_params_end_0550:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0550
	jmp .L_lambda_simple_end_0550
.L_lambda_simple_code_0550:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0550
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0550:
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
.L_tc_recycle_frame_loop_06ed:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ed
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06ed
.L_tc_recycle_frame_done_06ed:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0550:	; new closure is in rax
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
.L_tc_recycle_frame_loop_06ee:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ee
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06ee
.L_tc_recycle_frame_done_06ee:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_054f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0551:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0551
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0551
.L_lambda_simple_env_end_0551:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0551:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0551
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0551
.L_lambda_simple_params_end_0551:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0551
	jmp .L_lambda_simple_end_0551
.L_lambda_simple_code_0551:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0551
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0551:
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
.L_lambda_simple_env_loop_0552:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0552
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0552
.L_lambda_simple_env_end_0552:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0552:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0552
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0552
.L_lambda_simple_params_end_0552:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0552
	jmp .L_lambda_simple_end_0552
.L_lambda_simple_code_0552:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0552
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0552:
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
	je .L_if_else_03d7
	mov rax, PARAM(0)	; param s1

	jmp .L_if_end_03d7

	.L_if_else_03d7:
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
.L_tc_recycle_frame_loop_06ef:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ef
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06ef
.L_tc_recycle_frame_done_06ef:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03d7:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0552:	; new closure is in rax

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
.L_lambda_simple_env_loop_0553:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0553
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0553
.L_lambda_simple_env_end_0553:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0553:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0553
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0553
.L_lambda_simple_params_end_0553:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0553
	jmp .L_lambda_simple_end_0553
.L_lambda_simple_code_0553:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0553
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0553:
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
	je .L_if_else_03d8
	mov rax, PARAM(1)	; param s2

	jmp .L_if_end_03d8

	.L_if_else_03d8:
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
.L_tc_recycle_frame_loop_06f0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06f0
.L_tc_recycle_frame_done_06f0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03d8:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0553:	; new closure is in rax

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
.L_lambda_opt_env_loop_00b6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00b6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b6
.L_lambda_opt_env_end_00b6:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b6:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_00b6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b6
.L_lambda_opt_params_end_00b6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b6
	jmp .L_lambda_opt_end_00b6
.L_lambda_opt_code_00b6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00b6 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00b6 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00b6:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00b6:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00b6
	.L_lambda_opt_exact_shifting_loop_end_00b6:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00b6
	.L_lambda_opt_arity_check_more_00b6:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00b6
	.L_lambda_opt_stack_shrink_loop_00b6:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00b6:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00b6
	.L_lambda_opt_more_shifting_loop_end_00b6:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_00b6
	.L_lambda_opt_stack_shrink_loop_exit_00b6:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00b6:
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
	je .L_if_else_03d9
	mov rax, L_constants + 1

	jmp .L_if_end_03d9

	.L_if_else_03d9:
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
.L_tc_recycle_frame_loop_06f1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06f1
.L_tc_recycle_frame_done_06f1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03d9:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00b6:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0551:	; new closure is in rax
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
.L_lambda_simple_env_loop_0554:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0554
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0554
.L_lambda_simple_env_end_0554:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0554:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0554
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0554
.L_lambda_simple_params_end_0554:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0554
	jmp .L_lambda_simple_end_0554
.L_lambda_simple_code_0554:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0554
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0554:
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
.L_lambda_simple_env_loop_0555:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0555
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0555
.L_lambda_simple_env_end_0555:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0555:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0555
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0555
.L_lambda_simple_params_end_0555:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0555
	jmp .L_lambda_simple_end_0555
.L_lambda_simple_code_0555:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0555
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0555:
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
	je .L_if_else_03da
	mov rax, PARAM(1)	; param unit

	jmp .L_if_end_03da

	.L_if_else_03da:
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
.L_tc_recycle_frame_loop_06f2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06f2
.L_tc_recycle_frame_done_06f2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03da:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0555:	; new closure is in rax

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
.L_lambda_opt_env_loop_00b7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00b7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b7
.L_lambda_opt_env_end_00b7:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b7:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00b7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b7
.L_lambda_opt_params_end_00b7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b7
	jmp .L_lambda_opt_end_00b7
.L_lambda_opt_code_00b7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00b7 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00b7 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 2
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00b7:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00b7:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00b7
	.L_lambda_opt_exact_shifting_loop_end_00b7:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00b7
	.L_lambda_opt_arity_check_more_00b7:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 3;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00b7
	.L_lambda_opt_stack_shrink_loop_00b7:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00b7:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00b7
	.L_lambda_opt_more_shifting_loop_end_00b7:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 3
	jg .L_lambda_opt_stack_shrink_loop_00b7
	.L_lambda_opt_stack_shrink_loop_exit_00b7:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00b7:
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
.L_tc_recycle_frame_loop_06f3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06f3
.L_tc_recycle_frame_done_06f3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_00b7:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0554:	; new closure is in rax
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
.L_lambda_simple_env_loop_0556:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0556
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0556
.L_lambda_simple_env_end_0556:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0556:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0556
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0556
.L_lambda_simple_params_end_0556:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0556
	jmp .L_lambda_simple_end_0556
.L_lambda_simple_code_0556:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0556
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0556:
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
.L_lambda_simple_env_loop_0557:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0557
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0557
.L_lambda_simple_env_end_0557:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0557:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0557
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0557
.L_lambda_simple_params_end_0557:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0557
	jmp .L_lambda_simple_end_0557
.L_lambda_simple_code_0557:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0557
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0557:
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
	je .L_if_else_03db
	mov rax, PARAM(1)	; param unit

	jmp .L_if_end_03db

	.L_if_else_03db:
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
.L_tc_recycle_frame_loop_06f4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06f4
.L_tc_recycle_frame_done_06f4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03db:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0557:	; new closure is in rax

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
.L_lambda_opt_env_loop_00b8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00b8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b8
.L_lambda_opt_env_end_00b8:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b8:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00b8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b8
.L_lambda_opt_params_end_00b8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b8
	jmp .L_lambda_opt_end_00b8
.L_lambda_opt_code_00b8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00b8 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00b8 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 2
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00b8:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00b8:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00b8
	.L_lambda_opt_exact_shifting_loop_end_00b8:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00b8
	.L_lambda_opt_arity_check_more_00b8:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 3;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00b8
	.L_lambda_opt_stack_shrink_loop_00b8:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00b8:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00b8
	.L_lambda_opt_more_shifting_loop_end_00b8:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 3
	jg .L_lambda_opt_stack_shrink_loop_00b8
	.L_lambda_opt_stack_shrink_loop_exit_00b8:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00b8:
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
.L_tc_recycle_frame_loop_06f5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06f5
.L_tc_recycle_frame_done_06f5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_00b8:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0556:	; new closure is in rax
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
.L_lambda_simple_env_loop_0558:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0558
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0558
.L_lambda_simple_env_end_0558:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0558:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0558
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0558
.L_lambda_simple_params_end_0558:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0558
	jmp .L_lambda_simple_end_0558
.L_lambda_simple_code_0558:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0558
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0558:
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
.L_tc_recycle_frame_loop_06f6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06f6
.L_tc_recycle_frame_done_06f6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0558:	; new closure is in rax
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
.L_lambda_simple_env_loop_0559:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0559
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0559
.L_lambda_simple_env_end_0559:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0559:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0559
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0559
.L_lambda_simple_params_end_0559:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0559
	jmp .L_lambda_simple_end_0559
.L_lambda_simple_code_0559:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0559
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0559:
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
.L_lambda_simple_env_loop_055a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_055a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_055a
.L_lambda_simple_env_end_055a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_055a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_055a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_055a
.L_lambda_simple_params_end_055a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_055a
	jmp .L_lambda_simple_end_055a
.L_lambda_simple_code_055a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_055a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_055a:
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
	je .L_if_else_03dc
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
	je .L_if_else_03dd
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
.L_tc_recycle_frame_loop_06f7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06f7
.L_tc_recycle_frame_done_06f7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03dd

	.L_if_else_03dd:
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
	je .L_if_else_03de
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
.L_tc_recycle_frame_loop_06f8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06f8
.L_tc_recycle_frame_done_06f8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03de

	.L_if_else_03de:
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
	je .L_if_else_03df
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
.L_tc_recycle_frame_loop_06f9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06f9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06f9
.L_tc_recycle_frame_done_06f9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03df

	.L_if_else_03df:
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
.L_tc_recycle_frame_loop_06fa:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06fa
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06fa
.L_tc_recycle_frame_done_06fa:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03df:

	.L_if_end_03de:

	.L_if_end_03dd:

	jmp .L_if_end_03dc

	.L_if_else_03dc:
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
	je .L_if_else_03e0
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
	je .L_if_else_03e1
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
.L_tc_recycle_frame_loop_06fb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06fb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06fb
.L_tc_recycle_frame_done_06fb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03e1

	.L_if_else_03e1:
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
	je .L_if_else_03e2
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
.L_tc_recycle_frame_loop_06fc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06fc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06fc
.L_tc_recycle_frame_done_06fc:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03e2

	.L_if_else_03e2:
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
	je .L_if_else_03e3
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
.L_tc_recycle_frame_loop_06fd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06fd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06fd
.L_tc_recycle_frame_done_06fd:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03e3

	.L_if_else_03e3:
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
.L_tc_recycle_frame_loop_06fe:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06fe
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06fe
.L_tc_recycle_frame_done_06fe:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03e3:

	.L_if_end_03e2:

	.L_if_end_03e1:

	jmp .L_if_end_03e0

	.L_if_else_03e0:
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
	je .L_if_else_03e4
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
	je .L_if_else_03e5
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
.L_tc_recycle_frame_loop_06ff:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_06ff
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_06ff
.L_tc_recycle_frame_done_06ff:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03e5

	.L_if_else_03e5:
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
	je .L_if_else_03e6
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
.L_tc_recycle_frame_loop_0700:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0700
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0700
.L_tc_recycle_frame_done_0700:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03e6

	.L_if_else_03e6:
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
	je .L_if_else_03e7
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
.L_tc_recycle_frame_loop_0701:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0701
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0701
.L_tc_recycle_frame_done_0701:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03e7

	.L_if_else_03e7:
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
.L_tc_recycle_frame_loop_0702:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0702
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0702
.L_tc_recycle_frame_done_0702:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03e7:

	.L_if_end_03e6:

	.L_if_end_03e5:

	jmp .L_if_end_03e4

	.L_if_else_03e4:
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
.L_tc_recycle_frame_loop_0703:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0703
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0703
.L_tc_recycle_frame_done_0703:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03e4:

	.L_if_end_03e0:

	.L_if_end_03dc:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_055a:	; new closure is in rax
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
.L_lambda_simple_env_loop_055b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_055b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_055b
.L_lambda_simple_env_end_055b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_055b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_055b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_055b
.L_lambda_simple_params_end_055b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_055b
	jmp .L_lambda_simple_end_055b
.L_lambda_simple_code_055b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_055b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_055b:
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
.L_lambda_opt_env_loop_00b9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_00b9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00b9
.L_lambda_opt_env_end_00b9:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00b9:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00b9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00b9
.L_lambda_opt_params_end_00b9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00b9
	jmp .L_lambda_opt_end_00b9
.L_lambda_opt_code_00b9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00b9 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00b9 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00b9:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00b9:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00b9
	.L_lambda_opt_exact_shifting_loop_end_00b9:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00b9
	.L_lambda_opt_arity_check_more_00b9:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00b9
	.L_lambda_opt_stack_shrink_loop_00b9:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00b9:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00b9
	.L_lambda_opt_more_shifting_loop_end_00b9:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_00b9
	.L_lambda_opt_stack_shrink_loop_exit_00b9:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00b9:
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
.L_tc_recycle_frame_loop_0704:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0704
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0704
.L_tc_recycle_frame_done_0704:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00b9:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_055b:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0705:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0705
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0705
.L_tc_recycle_frame_done_0705:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0559:	; new closure is in rax
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
.L_lambda_simple_env_loop_055c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_055c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_055c
.L_lambda_simple_env_end_055c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_055c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_055c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_055c
.L_lambda_simple_params_end_055c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_055c
	jmp .L_lambda_simple_end_055c
.L_lambda_simple_code_055c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_055c
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_055c:
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
.L_tc_recycle_frame_loop_0706:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0706
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0706
.L_tc_recycle_frame_done_0706:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_055c:	; new closure is in rax
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
.L_lambda_simple_env_loop_055d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_055d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_055d
.L_lambda_simple_env_end_055d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_055d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_055d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_055d
.L_lambda_simple_params_end_055d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_055d
	jmp .L_lambda_simple_end_055d
.L_lambda_simple_code_055d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_055d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_055d:
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
.L_lambda_simple_env_loop_055e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_055e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_055e
.L_lambda_simple_env_end_055e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_055e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_055e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_055e
.L_lambda_simple_params_end_055e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_055e
	jmp .L_lambda_simple_end_055e
.L_lambda_simple_code_055e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_055e
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_055e:
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
	je .L_if_else_03e8
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
	je .L_if_else_03e9
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
.L_tc_recycle_frame_loop_0707:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0707
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0707
.L_tc_recycle_frame_done_0707:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03e9

	.L_if_else_03e9:
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
	je .L_if_else_03ea
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
.L_tc_recycle_frame_loop_0708:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0708
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0708
.L_tc_recycle_frame_done_0708:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03ea

	.L_if_else_03ea:
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
	je .L_if_else_03eb
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
.L_tc_recycle_frame_loop_0709:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0709
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0709
.L_tc_recycle_frame_done_0709:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03eb

	.L_if_else_03eb:
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
.L_tc_recycle_frame_loop_070a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_070a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_070a
.L_tc_recycle_frame_done_070a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03eb:

	.L_if_end_03ea:

	.L_if_end_03e9:

	jmp .L_if_end_03e8

	.L_if_else_03e8:
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
	je .L_if_else_03ec
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
	je .L_if_else_03ed
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
.L_tc_recycle_frame_loop_070b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_070b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_070b
.L_tc_recycle_frame_done_070b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03ed

	.L_if_else_03ed:
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
	je .L_if_else_03ee
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
.L_tc_recycle_frame_loop_070c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_070c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_070c
.L_tc_recycle_frame_done_070c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03ee

	.L_if_else_03ee:
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
	je .L_if_else_03ef
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
.L_tc_recycle_frame_loop_070d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_070d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_070d
.L_tc_recycle_frame_done_070d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03ef

	.L_if_else_03ef:
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
.L_tc_recycle_frame_loop_070e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_070e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_070e
.L_tc_recycle_frame_done_070e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03ef:

	.L_if_end_03ee:

	.L_if_end_03ed:

	jmp .L_if_end_03ec

	.L_if_else_03ec:
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
	je .L_if_else_03f0
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
	je .L_if_else_03f1
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
.L_tc_recycle_frame_loop_070f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_070f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_070f
.L_tc_recycle_frame_done_070f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03f1

	.L_if_else_03f1:
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
	je .L_if_else_03f2
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
.L_tc_recycle_frame_loop_0710:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0710
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0710
.L_tc_recycle_frame_done_0710:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03f2

	.L_if_else_03f2:
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
	je .L_if_else_03f3
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
.L_tc_recycle_frame_loop_0711:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0711
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0711
.L_tc_recycle_frame_done_0711:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03f3

	.L_if_else_03f3:
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
.L_tc_recycle_frame_loop_0712:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0712
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0712
.L_tc_recycle_frame_done_0712:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03f3:

	.L_if_end_03f2:

	.L_if_end_03f1:

	jmp .L_if_end_03f0

	.L_if_else_03f0:
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
.L_tc_recycle_frame_loop_0713:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0713
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0713
.L_tc_recycle_frame_done_0713:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03f0:

	.L_if_end_03ec:

	.L_if_end_03e8:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_055e:	; new closure is in rax
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
.L_lambda_simple_env_loop_055f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_055f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_055f
.L_lambda_simple_env_end_055f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_055f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_055f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_055f
.L_lambda_simple_params_end_055f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_055f
	jmp .L_lambda_simple_end_055f
.L_lambda_simple_code_055f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_055f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_055f:
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
.L_lambda_opt_env_loop_00ba:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_00ba
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00ba
.L_lambda_opt_env_end_00ba:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00ba:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00ba
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00ba
.L_lambda_opt_params_end_00ba:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00ba
	jmp .L_lambda_opt_end_00ba
.L_lambda_opt_code_00ba:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00ba ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00ba ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00ba:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00ba:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00ba
	.L_lambda_opt_exact_shifting_loop_end_00ba:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00ba
	.L_lambda_opt_arity_check_more_00ba:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00ba
	.L_lambda_opt_stack_shrink_loop_00ba:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00ba:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00ba
	.L_lambda_opt_more_shifting_loop_end_00ba:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_00ba
	.L_lambda_opt_stack_shrink_loop_exit_00ba:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00ba:
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
	je .L_if_else_03f4
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
.L_tc_recycle_frame_loop_0714:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0714
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0714
.L_tc_recycle_frame_done_0714:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03f4

	.L_if_else_03f4:
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
.L_lambda_simple_env_loop_0560:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0560
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0560
.L_lambda_simple_env_end_0560:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0560:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0560
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0560
.L_lambda_simple_params_end_0560:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0560
	jmp .L_lambda_simple_end_0560
.L_lambda_simple_code_0560:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0560
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0560:
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
.L_tc_recycle_frame_loop_0715:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0715
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0715
.L_tc_recycle_frame_done_0715:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0560:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0716:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0716
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0716
.L_tc_recycle_frame_done_0716:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03f4:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00ba:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_055f:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0717:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0717
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0717
.L_tc_recycle_frame_done_0717:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_055d:	; new closure is in rax
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
.L_lambda_simple_env_loop_0561:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0561
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0561
.L_lambda_simple_env_end_0561:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0561:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0561
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0561
.L_lambda_simple_params_end_0561:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0561
	jmp .L_lambda_simple_end_0561
.L_lambda_simple_code_0561:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0561
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0561:
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
.L_tc_recycle_frame_loop_0718:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0718
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0718
.L_tc_recycle_frame_done_0718:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0561:	; new closure is in rax
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
.L_lambda_simple_env_loop_0562:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0562
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0562
.L_lambda_simple_env_end_0562:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0562:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0562
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0562
.L_lambda_simple_params_end_0562:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0562
	jmp .L_lambda_simple_end_0562
.L_lambda_simple_code_0562:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0562
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0562:
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
.L_lambda_simple_env_loop_0563:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0563
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0563
.L_lambda_simple_env_end_0563:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0563:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0563
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0563
.L_lambda_simple_params_end_0563:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0563
	jmp .L_lambda_simple_end_0563
.L_lambda_simple_code_0563:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0563
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0563:
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
	je .L_if_else_03f5
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
	je .L_if_else_03f6
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
.L_tc_recycle_frame_loop_0719:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0719
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0719
.L_tc_recycle_frame_done_0719:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03f6

	.L_if_else_03f6:
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
	je .L_if_else_03f7
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
.L_tc_recycle_frame_loop_071a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_071a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_071a
.L_tc_recycle_frame_done_071a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03f7

	.L_if_else_03f7:
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
	je .L_if_else_03f8
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
.L_tc_recycle_frame_loop_071b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_071b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_071b
.L_tc_recycle_frame_done_071b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03f8

	.L_if_else_03f8:
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
.L_tc_recycle_frame_loop_071c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_071c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_071c
.L_tc_recycle_frame_done_071c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03f8:

	.L_if_end_03f7:

	.L_if_end_03f6:

	jmp .L_if_end_03f5

	.L_if_else_03f5:
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
	je .L_if_else_03f9
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
	je .L_if_else_03fa
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
.L_tc_recycle_frame_loop_071d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_071d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_071d
.L_tc_recycle_frame_done_071d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03fa

	.L_if_else_03fa:
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
	je .L_if_else_03fb
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
.L_tc_recycle_frame_loop_071e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_071e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_071e
.L_tc_recycle_frame_done_071e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03fb

	.L_if_else_03fb:
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
	je .L_if_else_03fc
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
.L_tc_recycle_frame_loop_071f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_071f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_071f
.L_tc_recycle_frame_done_071f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03fc

	.L_if_else_03fc:
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
.L_tc_recycle_frame_loop_0720:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0720
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0720
.L_tc_recycle_frame_done_0720:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03fc:

	.L_if_end_03fb:

	.L_if_end_03fa:

	jmp .L_if_end_03f9

	.L_if_else_03f9:
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
	je .L_if_else_03fd
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
	je .L_if_else_03fe
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
.L_tc_recycle_frame_loop_0721:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0721
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0721
.L_tc_recycle_frame_done_0721:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03fe

	.L_if_else_03fe:
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
	je .L_if_else_03ff
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
.L_tc_recycle_frame_loop_0722:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0722
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0722
.L_tc_recycle_frame_done_0722:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_03ff

	.L_if_else_03ff:
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
	je .L_if_else_0400
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
.L_tc_recycle_frame_loop_0723:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0723
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0723
.L_tc_recycle_frame_done_0723:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0400

	.L_if_else_0400:
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
.L_tc_recycle_frame_loop_0724:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0724
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0724
.L_tc_recycle_frame_done_0724:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_0400:

	.L_if_end_03ff:

	.L_if_end_03fe:

	jmp .L_if_end_03fd

	.L_if_else_03fd:
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
.L_tc_recycle_frame_loop_0725:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0725
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0725
.L_tc_recycle_frame_done_0725:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_03fd:

	.L_if_end_03f9:

	.L_if_end_03f5:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0563:	; new closure is in rax
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
.L_lambda_simple_env_loop_0564:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0564
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0564
.L_lambda_simple_env_end_0564:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0564:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0564
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0564
.L_lambda_simple_params_end_0564:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0564
	jmp .L_lambda_simple_end_0564
.L_lambda_simple_code_0564:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0564
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0564:
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
.L_lambda_opt_env_loop_00bb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_00bb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00bb
.L_lambda_opt_env_end_00bb:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00bb:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00bb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00bb
.L_lambda_opt_params_end_00bb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00bb
	jmp .L_lambda_opt_end_00bb
.L_lambda_opt_code_00bb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00bb ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00bb ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00bb:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00bb:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00bb
	.L_lambda_opt_exact_shifting_loop_end_00bb:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00bb
	.L_lambda_opt_arity_check_more_00bb:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00bb
	.L_lambda_opt_stack_shrink_loop_00bb:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00bb:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00bb
	.L_lambda_opt_more_shifting_loop_end_00bb:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_00bb
	.L_lambda_opt_stack_shrink_loop_exit_00bb:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00bb:
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
.L_tc_recycle_frame_loop_0726:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0726
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0726
.L_tc_recycle_frame_done_0726:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00bb:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0564:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0727:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0727
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0727
.L_tc_recycle_frame_done_0727:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0562:	; new closure is in rax
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
.L_lambda_simple_env_loop_0565:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0565
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0565
.L_lambda_simple_env_end_0565:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0565:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0565
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0565
.L_lambda_simple_params_end_0565:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0565
	jmp .L_lambda_simple_end_0565
.L_lambda_simple_code_0565:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0565
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0565:
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
.L_tc_recycle_frame_loop_0728:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0728
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0728
.L_tc_recycle_frame_done_0728:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0565:	; new closure is in rax
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
.L_lambda_simple_env_loop_0566:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0566
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0566
.L_lambda_simple_env_end_0566:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0566:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0566
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0566
.L_lambda_simple_params_end_0566:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0566
	jmp .L_lambda_simple_end_0566
.L_lambda_simple_code_0566:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0566
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0566:
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
.L_lambda_simple_env_loop_0567:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0567
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0567
.L_lambda_simple_env_end_0567:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0567:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0567
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0567
.L_lambda_simple_params_end_0567:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0567
	jmp .L_lambda_simple_end_0567
.L_lambda_simple_code_0567:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0567
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0567:
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
	je .L_if_else_0401
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
	je .L_if_else_0402
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
.L_tc_recycle_frame_loop_0729:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0729
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0729
.L_tc_recycle_frame_done_0729:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0402

	.L_if_else_0402:
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
	je .L_if_else_0403
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
.L_tc_recycle_frame_loop_072a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_072a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_072a
.L_tc_recycle_frame_done_072a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0403

	.L_if_else_0403:
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
	je .L_if_else_0404
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
.L_tc_recycle_frame_loop_072b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_072b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_072b
.L_tc_recycle_frame_done_072b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0404

	.L_if_else_0404:
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
.L_tc_recycle_frame_loop_072c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_072c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_072c
.L_tc_recycle_frame_done_072c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_0404:

	.L_if_end_0403:

	.L_if_end_0402:

	jmp .L_if_end_0401

	.L_if_else_0401:
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
	je .L_if_else_0405
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
	je .L_if_else_0406
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
.L_tc_recycle_frame_loop_072d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_072d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_072d
.L_tc_recycle_frame_done_072d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0406

	.L_if_else_0406:
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
	je .L_if_else_0407
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
.L_tc_recycle_frame_loop_072e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_072e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_072e
.L_tc_recycle_frame_done_072e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0407

	.L_if_else_0407:
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
	je .L_if_else_0408
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
.L_tc_recycle_frame_loop_072f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_072f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_072f
.L_tc_recycle_frame_done_072f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0408

	.L_if_else_0408:
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
.L_tc_recycle_frame_loop_0730:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0730
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0730
.L_tc_recycle_frame_done_0730:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_0408:

	.L_if_end_0407:

	.L_if_end_0406:

	jmp .L_if_end_0405

	.L_if_else_0405:
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
	je .L_if_else_0409
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
	je .L_if_else_040a
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
.L_tc_recycle_frame_loop_0731:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0731
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0731
.L_tc_recycle_frame_done_0731:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_040a

	.L_if_else_040a:
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
	je .L_if_else_040b
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
.L_tc_recycle_frame_loop_0732:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0732
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0732
.L_tc_recycle_frame_done_0732:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_040b

	.L_if_else_040b:
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
	je .L_if_else_040c
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
.L_tc_recycle_frame_loop_0733:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0733
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0733
.L_tc_recycle_frame_done_0733:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_040c

	.L_if_else_040c:
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
.L_tc_recycle_frame_loop_0734:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0734
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0734
.L_tc_recycle_frame_done_0734:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_040c:

	.L_if_end_040b:

	.L_if_end_040a:

	jmp .L_if_end_0409

	.L_if_else_0409:
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
.L_tc_recycle_frame_loop_0735:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0735
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0735
.L_tc_recycle_frame_done_0735:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_0409:

	.L_if_end_0405:

	.L_if_end_0401:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0567:	; new closure is in rax
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
.L_lambda_simple_env_loop_0568:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0568
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0568
.L_lambda_simple_env_end_0568:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0568:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0568
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0568
.L_lambda_simple_params_end_0568:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0568
	jmp .L_lambda_simple_end_0568
.L_lambda_simple_code_0568:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0568
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0568:
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
.L_lambda_opt_env_loop_00bc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_00bc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00bc
.L_lambda_opt_env_end_00bc:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00bc:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00bc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00bc
.L_lambda_opt_params_end_00bc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00bc
	jmp .L_lambda_opt_end_00bc
.L_lambda_opt_code_00bc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00bc ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00bc ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00bc:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00bc:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00bc
	.L_lambda_opt_exact_shifting_loop_end_00bc:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00bc
	.L_lambda_opt_arity_check_more_00bc:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00bc
	.L_lambda_opt_stack_shrink_loop_00bc:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00bc:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00bc
	.L_lambda_opt_more_shifting_loop_end_00bc:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_00bc
	.L_lambda_opt_stack_shrink_loop_exit_00bc:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00bc:
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
	je .L_if_else_040d
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
.L_tc_recycle_frame_loop_0736:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0736
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0736
.L_tc_recycle_frame_done_0736:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_040d

	.L_if_else_040d:
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
.L_lambda_simple_env_loop_0569:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0569
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0569
.L_lambda_simple_env_end_0569:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0569:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0569
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0569
.L_lambda_simple_params_end_0569:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0569
	jmp .L_lambda_simple_end_0569
.L_lambda_simple_code_0569:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0569
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0569:
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
.L_tc_recycle_frame_loop_0737:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0737
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0737
.L_tc_recycle_frame_done_0737:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0569:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0738:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0738
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0738
.L_tc_recycle_frame_done_0738:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_040d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00bc:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0568:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0739:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0739
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0739
.L_tc_recycle_frame_done_0739:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0566:	; new closure is in rax
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
.L_lambda_simple_env_loop_056a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_056a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_056a
.L_lambda_simple_env_end_056a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_056a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_056a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_056a
.L_lambda_simple_params_end_056a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_056a
	jmp .L_lambda_simple_end_056a
.L_lambda_simple_code_056a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_056a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_056a:
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
	je .L_if_else_040e
	mov rax, L_constants + 2158

	jmp .L_if_end_040e

	.L_if_else_040e:
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
.L_tc_recycle_frame_loop_073a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_073a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_073a
.L_tc_recycle_frame_done_073a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_040e:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_056a:	; new closure is in rax
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
.L_lambda_simple_env_loop_056b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_056b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_056b
.L_lambda_simple_env_end_056b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_056b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_056b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_056b
.L_lambda_simple_params_end_056b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_056b
	jmp .L_lambda_simple_end_056b
.L_lambda_simple_code_056b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_056b
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_056b:
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
.L_tc_recycle_frame_loop_073b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_073b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_073b
.L_tc_recycle_frame_done_073b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_056b:	; new closure is in rax
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
.L_lambda_simple_env_loop_056c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_056c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_056c
.L_lambda_simple_env_end_056c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_056c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_056c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_056c
.L_lambda_simple_params_end_056c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_056c
	jmp .L_lambda_simple_end_056c
.L_lambda_simple_code_056c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_056c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_056c:
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
.L_lambda_simple_env_loop_056d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_056d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_056d
.L_lambda_simple_env_end_056d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_056d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_056d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_056d
.L_lambda_simple_params_end_056d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_056d
	jmp .L_lambda_simple_end_056d
.L_lambda_simple_code_056d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_056d
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_056d:
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
.L_lambda_simple_env_loop_056e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_056e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_056e
.L_lambda_simple_env_end_056e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_056e:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_056e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_056e
.L_lambda_simple_params_end_056e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_056e
	jmp .L_lambda_simple_end_056e
.L_lambda_simple_code_056e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_056e
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_056e:
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
	je .L_if_else_040f
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
	je .L_if_else_0410
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
.L_tc_recycle_frame_loop_073c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_073c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_073c
.L_tc_recycle_frame_done_073c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0410

	.L_if_else_0410:
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
	je .L_if_else_0411
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
.L_tc_recycle_frame_loop_073d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_073d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_073d
.L_tc_recycle_frame_done_073d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0411

	.L_if_else_0411:
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
	je .L_if_else_0412
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
.L_tc_recycle_frame_loop_073e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_073e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_073e
.L_tc_recycle_frame_done_073e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0412

	.L_if_else_0412:
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
.L_tc_recycle_frame_loop_073f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_073f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_073f
.L_tc_recycle_frame_done_073f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_0412:

	.L_if_end_0411:

	.L_if_end_0410:

	jmp .L_if_end_040f

	.L_if_else_040f:
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
	je .L_if_else_0413
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
	je .L_if_else_0414
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
.L_tc_recycle_frame_loop_0740:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0740
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0740
.L_tc_recycle_frame_done_0740:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0414

	.L_if_else_0414:
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
	je .L_if_else_0415
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
.L_tc_recycle_frame_loop_0741:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0741
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0741
.L_tc_recycle_frame_done_0741:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0415

	.L_if_else_0415:
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
	je .L_if_else_0416
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
.L_tc_recycle_frame_loop_0742:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0742
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0742
.L_tc_recycle_frame_done_0742:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0416

	.L_if_else_0416:
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
.L_tc_recycle_frame_loop_0743:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0743
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0743
.L_tc_recycle_frame_done_0743:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_0416:

	.L_if_end_0415:

	.L_if_end_0414:

	jmp .L_if_end_0413

	.L_if_else_0413:
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
	je .L_if_else_0417
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
	je .L_if_else_0418
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
.L_tc_recycle_frame_loop_0744:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0744
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0744
.L_tc_recycle_frame_done_0744:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0418

	.L_if_else_0418:
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
	je .L_if_else_0419
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
.L_tc_recycle_frame_loop_0745:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0745
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0745
.L_tc_recycle_frame_done_0745:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0419

	.L_if_else_0419:
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
	je .L_if_else_041a
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
.L_tc_recycle_frame_loop_0746:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0746
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0746
.L_tc_recycle_frame_done_0746:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_041a

	.L_if_else_041a:
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
.L_tc_recycle_frame_loop_0747:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0747
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0747
.L_tc_recycle_frame_done_0747:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_041a:

	.L_if_end_0419:

	.L_if_end_0418:

	jmp .L_if_end_0417

	.L_if_else_0417:
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
.L_tc_recycle_frame_loop_0748:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0748
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0748
.L_tc_recycle_frame_done_0748:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_0417:

	.L_if_end_0413:

	.L_if_end_040f:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_056e:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_056d:	; new closure is in rax
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
.L_lambda_simple_env_loop_056f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_056f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_056f
.L_lambda_simple_env_end_056f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_056f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_056f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_056f
.L_lambda_simple_params_end_056f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_056f
	jmp .L_lambda_simple_end_056f
.L_lambda_simple_code_056f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_056f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_056f:
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
.L_lambda_simple_env_loop_0570:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0570
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0570
.L_lambda_simple_env_end_0570:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0570:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0570
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0570
.L_lambda_simple_params_end_0570:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0570
	jmp .L_lambda_simple_end_0570
.L_lambda_simple_code_0570:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0570
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0570:
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
.L_lambda_simple_env_loop_0571:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0571
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0571
.L_lambda_simple_env_end_0571:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0571:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0571
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0571
.L_lambda_simple_params_end_0571:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0571
	jmp .L_lambda_simple_end_0571
.L_lambda_simple_code_0571:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0571
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0571:
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
.L_lambda_simple_env_loop_0572:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0572
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0572
.L_lambda_simple_env_end_0572:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0572:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0572
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0572
.L_lambda_simple_params_end_0572:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0572
	jmp .L_lambda_simple_end_0572
.L_lambda_simple_code_0572:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0572
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0572:
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
.L_tc_recycle_frame_loop_0749:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0749
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0749
.L_tc_recycle_frame_done_0749:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0572:	; new closure is in rax
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
.L_lambda_simple_env_loop_0573:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0573
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0573
.L_lambda_simple_env_end_0573:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0573:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0573
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0573
.L_lambda_simple_params_end_0573:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0573
	jmp .L_lambda_simple_end_0573
.L_lambda_simple_code_0573:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0573
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0573:
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
.L_lambda_simple_env_loop_0574:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_0574
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0574
.L_lambda_simple_env_end_0574:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0574:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0574
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0574
.L_lambda_simple_params_end_0574:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0574
	jmp .L_lambda_simple_end_0574
.L_lambda_simple_code_0574:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0574
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0574:
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
.L_tc_recycle_frame_loop_074a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_074a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_074a
.L_tc_recycle_frame_done_074a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0574:	; new closure is in rax
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
.L_lambda_simple_env_loop_0575:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_0575
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0575
.L_lambda_simple_env_end_0575:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0575:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0575
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0575
.L_lambda_simple_params_end_0575:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0575
	jmp .L_lambda_simple_end_0575
.L_lambda_simple_code_0575:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0575
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0575:
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
.L_lambda_simple_env_loop_0576:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_0576
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0576
.L_lambda_simple_env_end_0576:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0576:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0576
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0576
.L_lambda_simple_params_end_0576:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0576
	jmp .L_lambda_simple_end_0576
.L_lambda_simple_code_0576:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0576
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0576:
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
.L_tc_recycle_frame_loop_074b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_074b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_074b
.L_tc_recycle_frame_done_074b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0576:	; new closure is in rax
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
.L_lambda_simple_env_loop_0577:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_0577
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0577
.L_lambda_simple_env_end_0577:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0577:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0577
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0577
.L_lambda_simple_params_end_0577:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0577
	jmp .L_lambda_simple_end_0577
.L_lambda_simple_code_0577:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0577
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0577:
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
.L_lambda_simple_env_loop_0578:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_0578
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0578
.L_lambda_simple_env_end_0578:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0578:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0578
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0578
.L_lambda_simple_params_end_0578:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0578
	jmp .L_lambda_simple_end_0578
.L_lambda_simple_code_0578:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0578
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0578:
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
.L_lambda_simple_env_loop_0579:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_0579
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0579
.L_lambda_simple_env_end_0579:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0579:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0579
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0579
.L_lambda_simple_params_end_0579:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0579
	jmp .L_lambda_simple_end_0579
.L_lambda_simple_code_0579:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0579
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0579:
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
.L_lambda_simple_env_loop_057a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 9
	je .L_lambda_simple_env_end_057a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_057a
.L_lambda_simple_env_end_057a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_057a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_057a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_057a
.L_lambda_simple_params_end_057a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_057a
	jmp .L_lambda_simple_end_057a
.L_lambda_simple_code_057a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_057a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_057a:
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
	jne .L_or_end_0060
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
	je .L_if_else_041b
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
.L_tc_recycle_frame_loop_074c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_074c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_074c
.L_tc_recycle_frame_done_074c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_041b

	.L_if_else_041b:
	mov rax, L_constants + 2

	.L_if_end_041b:
.L_or_end_0060:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_057a:	; new closure is in rax

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
.L_lambda_opt_env_loop_00bd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 9
	je .L_lambda_opt_env_end_00bd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00bd
.L_lambda_opt_env_end_00bd:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00bd:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00bd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00bd
.L_lambda_opt_params_end_00bd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00bd
	jmp .L_lambda_opt_end_00bd
.L_lambda_opt_code_00bd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00bd ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00bd ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00bd:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00bd:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00bd
	.L_lambda_opt_exact_shifting_loop_end_00bd:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00bd
	.L_lambda_opt_arity_check_more_00bd:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00bd
	.L_lambda_opt_stack_shrink_loop_00bd:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00bd:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00bd
	.L_lambda_opt_more_shifting_loop_end_00bd:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_00bd
	.L_lambda_opt_stack_shrink_loop_exit_00bd:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00bd:
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
.L_tc_recycle_frame_loop_074d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_074d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_074d
.L_tc_recycle_frame_done_074d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00bd:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0579:	; new closure is in rax
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
.L_tc_recycle_frame_loop_074e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_074e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_074e
.L_tc_recycle_frame_done_074e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0578:	; new closure is in rax
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
.L_lambda_simple_env_loop_057b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_057b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_057b
.L_lambda_simple_env_end_057b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_057b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_057b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_057b
.L_lambda_simple_params_end_057b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_057b
	jmp .L_lambda_simple_end_057b
.L_lambda_simple_code_057b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_057b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_057b:
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
.L_lambda_simple_end_057b:	; new closure is in rax
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
.L_tc_recycle_frame_loop_074f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_074f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_074f
.L_tc_recycle_frame_done_074f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0577:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0750:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0750
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0750
.L_tc_recycle_frame_done_0750:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0575:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0751:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0751
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0751
.L_tc_recycle_frame_done_0751:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0573:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0752:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0752
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0752
.L_tc_recycle_frame_done_0752:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0571:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0753:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0753
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0753
.L_tc_recycle_frame_done_0753:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0570:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0754:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0754
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0754
.L_tc_recycle_frame_done_0754:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_056f:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0755:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0755
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0755
.L_tc_recycle_frame_done_0755:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_056c:	; new closure is in rax
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
.L_lambda_simple_env_loop_057c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_057c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_057c
.L_lambda_simple_env_end_057c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_057c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_057c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_057c
.L_lambda_simple_params_end_057c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_057c
	jmp .L_lambda_simple_end_057c
.L_lambda_simple_code_057c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_057c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_057c:
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
.L_lambda_simple_env_loop_057d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_057d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_057d
.L_lambda_simple_env_end_057d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_057d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_057d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_057d
.L_lambda_simple_params_end_057d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_057d
	jmp .L_lambda_simple_end_057d
.L_lambda_simple_code_057d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_057d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_057d:
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
	je .L_if_else_041c
	mov rax, L_constants + 1

	jmp .L_if_end_041c

	.L_if_else_041c:
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
.L_tc_recycle_frame_loop_0756:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0756
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0756
.L_tc_recycle_frame_done_0756:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_041c:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_057d:	; new closure is in rax

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
.L_lambda_opt_env_loop_00be:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00be
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00be
.L_lambda_opt_env_end_00be:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00be:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00be
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00be
.L_lambda_opt_params_end_00be:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00be
	jmp .L_lambda_opt_end_00be
.L_lambda_opt_code_00be:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00be ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00be ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00be:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00be:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00be
	.L_lambda_opt_exact_shifting_loop_end_00be:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00be
	.L_lambda_opt_arity_check_more_00be:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00be
	.L_lambda_opt_stack_shrink_loop_00be:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00be:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00be
	.L_lambda_opt_more_shifting_loop_end_00be:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_00be
	.L_lambda_opt_stack_shrink_loop_exit_00be:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00be:
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
	je .L_if_else_041d
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
.L_tc_recycle_frame_loop_0757:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0757
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0757
.L_tc_recycle_frame_done_0757:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_041d

	.L_if_else_041d:
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
	je .L_if_else_041f
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

	jmp .L_if_end_041f

	.L_if_else_041f:
	mov rax, L_constants + 2

	.L_if_end_041f:

	cmp rax, sob_boolean_false
	je .L_if_else_041e
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
.L_tc_recycle_frame_loop_0758:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0758
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0758
.L_tc_recycle_frame_done_0758:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_041e

	.L_if_else_041e:
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
.L_tc_recycle_frame_loop_0759:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0759
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0759
.L_tc_recycle_frame_done_0759:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_041e:

	.L_if_end_041d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00be:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_057c:	; new closure is in rax
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
.L_lambda_simple_env_loop_057e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_057e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_057e
.L_lambda_simple_env_end_057e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_057e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_057e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_057e
.L_lambda_simple_params_end_057e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_057e
	jmp .L_lambda_simple_end_057e
.L_lambda_simple_code_057e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_057e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_057e:
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
.L_lambda_opt_env_loop_00bf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00bf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00bf
.L_lambda_opt_env_end_00bf:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00bf:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00bf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00bf
.L_lambda_opt_params_end_00bf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00bf
	jmp .L_lambda_opt_end_00bf
.L_lambda_opt_code_00bf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00bf ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00bf ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00bf:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00bf:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00bf
	.L_lambda_opt_exact_shifting_loop_end_00bf:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00bf
	.L_lambda_opt_arity_check_more_00bf:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00bf
	.L_lambda_opt_stack_shrink_loop_00bf:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00bf:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00bf
	.L_lambda_opt_more_shifting_loop_end_00bf:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_00bf
	.L_lambda_opt_stack_shrink_loop_exit_00bf:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00bf:
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
.L_tc_recycle_frame_loop_075a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_075a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_075a
.L_tc_recycle_frame_done_075a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00bf:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_057e:	; new closure is in rax
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
.L_lambda_simple_env_loop_057f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_057f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_057f
.L_lambda_simple_env_end_057f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_057f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_057f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_057f
.L_lambda_simple_params_end_057f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_057f
	jmp .L_lambda_simple_end_057f
.L_lambda_simple_code_057f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_057f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_057f:
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
.L_lambda_simple_end_057f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0580:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0580
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0580
.L_lambda_simple_env_end_0580:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0580:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0580
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0580
.L_lambda_simple_params_end_0580:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0580
	jmp .L_lambda_simple_end_0580
.L_lambda_simple_code_0580:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0580
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0580:
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
.L_lambda_simple_env_loop_0581:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0581
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0581
.L_lambda_simple_env_end_0581:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0581:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0581
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0581
.L_lambda_simple_params_end_0581:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0581
	jmp .L_lambda_simple_end_0581
.L_lambda_simple_code_0581:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0581
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0581:
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
	je .L_if_else_0420
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
.L_tc_recycle_frame_loop_075b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_075b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_075b
.L_tc_recycle_frame_done_075b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0420

	.L_if_else_0420:
	mov rax, PARAM(0)	; param ch

	.L_if_end_0420:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0581:	; new closure is in rax
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
.L_lambda_simple_env_loop_0582:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0582
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0582
.L_lambda_simple_env_end_0582:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0582:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0582
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0582
.L_lambda_simple_params_end_0582:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0582
	jmp .L_lambda_simple_end_0582
.L_lambda_simple_code_0582:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0582
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0582:
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
	je .L_if_else_0421
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
.L_tc_recycle_frame_loop_075c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_075c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_075c
.L_tc_recycle_frame_done_075c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0421

	.L_if_else_0421:
	mov rax, PARAM(0)	; param ch

	.L_if_end_0421:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0582:	; new closure is in rax
	mov qword [free_var_134], rax	; free var char-upcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0580:	; new closure is in rax
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
.L_lambda_simple_env_loop_0583:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0583
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0583
.L_lambda_simple_env_end_0583:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0583:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0583
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0583
.L_lambda_simple_params_end_0583:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0583
	jmp .L_lambda_simple_end_0583
.L_lambda_simple_code_0583:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0583
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0583:
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
.L_lambda_opt_env_loop_00c0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00c0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00c0
.L_lambda_opt_env_end_00c0:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00c0:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00c0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00c0
.L_lambda_opt_params_end_00c0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00c0
	jmp .L_lambda_opt_end_00c0
.L_lambda_opt_code_00c0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00c0 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00c0 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00c0:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00c0:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00c0
	.L_lambda_opt_exact_shifting_loop_end_00c0:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00c0
	.L_lambda_opt_arity_check_more_00c0:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00c0
	.L_lambda_opt_stack_shrink_loop_00c0:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00c0:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00c0
	.L_lambda_opt_more_shifting_loop_end_00c0:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_00c0
	.L_lambda_opt_stack_shrink_loop_exit_00c0:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00c0:
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
.L_lambda_simple_env_loop_0584:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0584
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0584
.L_lambda_simple_env_end_0584:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0584:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0584
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0584
.L_lambda_simple_params_end_0584:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0584
	jmp .L_lambda_simple_end_0584
.L_lambda_simple_code_0584:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0584
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0584:
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
.L_tc_recycle_frame_loop_075d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_075d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_075d
.L_tc_recycle_frame_done_075d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0584:	; new closure is in rax
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
.L_tc_recycle_frame_loop_075e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_075e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_075e
.L_tc_recycle_frame_done_075e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00c0:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0583:	; new closure is in rax
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
.L_lambda_simple_env_loop_0585:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0585
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0585
.L_lambda_simple_env_end_0585:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0585:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0585
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0585
.L_lambda_simple_params_end_0585:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0585
	jmp .L_lambda_simple_end_0585
.L_lambda_simple_code_0585:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0585
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0585:
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
.L_lambda_simple_end_0585:	; new closure is in rax
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
.L_lambda_simple_env_loop_0586:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0586
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0586
.L_lambda_simple_env_end_0586:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0586:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0586
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0586
.L_lambda_simple_params_end_0586:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0586
	jmp .L_lambda_simple_end_0586
.L_lambda_simple_code_0586:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0586
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0586:
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
.L_lambda_simple_env_loop_0587:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0587
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0587
.L_lambda_simple_env_end_0587:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0587:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0587
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0587
.L_lambda_simple_params_end_0587:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0587
	jmp .L_lambda_simple_end_0587
.L_lambda_simple_code_0587:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0587
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0587:
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
.L_tc_recycle_frame_loop_075f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_075f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_075f
.L_tc_recycle_frame_done_075f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0587:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0586:	; new closure is in rax
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
.L_lambda_simple_env_loop_0588:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0588
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0588
.L_lambda_simple_env_end_0588:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0588:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0588
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0588
.L_lambda_simple_params_end_0588:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0588
	jmp .L_lambda_simple_end_0588
.L_lambda_simple_code_0588:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0588
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0588:
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
.L_lambda_simple_end_0588:	; new closure is in rax
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
.L_lambda_simple_env_loop_0589:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0589
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0589
.L_lambda_simple_env_end_0589:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0589:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0589
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0589
.L_lambda_simple_params_end_0589:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0589
	jmp .L_lambda_simple_end_0589
.L_lambda_simple_code_0589:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0589
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0589:
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
.L_lambda_simple_env_loop_058a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_058a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_058a
.L_lambda_simple_env_end_058a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_058a:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_058a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_058a
.L_lambda_simple_params_end_058a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_058a
	jmp .L_lambda_simple_end_058a
.L_lambda_simple_code_058a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_058a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_058a:
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
.L_lambda_simple_env_loop_058b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_058b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_058b
.L_lambda_simple_env_end_058b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_058b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_058b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_058b
.L_lambda_simple_params_end_058b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_058b
	jmp .L_lambda_simple_end_058b
.L_lambda_simple_code_058b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_058b
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_058b:
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
	je .L_if_else_0422
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

	jmp .L_if_end_0422

	.L_if_else_0422:
	mov rax, L_constants + 2

	.L_if_end_0422:
	cmp rax, sob_boolean_false
	jne .L_or_end_0061
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
	je .L_if_else_0423
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
	jne .L_or_end_0062
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
	je .L_if_else_0424
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
.L_tc_recycle_frame_loop_0760:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0760
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0760
.L_tc_recycle_frame_done_0760:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0424

	.L_if_else_0424:
	mov rax, L_constants + 2

	.L_if_end_0424:
.L_or_end_0062:

	jmp .L_if_end_0423

	.L_if_else_0423:
	mov rax, L_constants + 2

	.L_if_end_0423:
.L_or_end_0061:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_058b:	; new closure is in rax

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
.L_lambda_simple_env_loop_058c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_058c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_058c
.L_lambda_simple_env_end_058c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_058c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_058c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_058c
.L_lambda_simple_params_end_058c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_058c
	jmp .L_lambda_simple_end_058c
.L_lambda_simple_code_058c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_058c
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_058c:
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
.L_lambda_simple_env_loop_058d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_058d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_058d
.L_lambda_simple_env_end_058d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_058d:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_058d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_058d
.L_lambda_simple_params_end_058d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_058d
	jmp .L_lambda_simple_end_058d
.L_lambda_simple_code_058d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_058d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_058d:
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
	je .L_if_else_0425
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
.L_tc_recycle_frame_loop_0761:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0761
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0761
.L_tc_recycle_frame_done_0761:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0425

	.L_if_else_0425:
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
.L_tc_recycle_frame_loop_0762:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0762
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0762
.L_tc_recycle_frame_done_0762:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_0425:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_058d:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0763:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0763
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0763
.L_tc_recycle_frame_done_0763:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_058c:	; new closure is in rax
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
.L_lambda_simple_env_loop_058e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_058e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_058e
.L_lambda_simple_env_end_058e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_058e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_058e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_058e
.L_lambda_simple_params_end_058e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_058e
	jmp .L_lambda_simple_end_058e
.L_lambda_simple_code_058e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_058e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_058e:
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
.L_lambda_simple_env_loop_058f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_058f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_058f
.L_lambda_simple_env_end_058f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_058f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_058f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_058f
.L_lambda_simple_params_end_058f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_058f
	jmp .L_lambda_simple_end_058f
.L_lambda_simple_code_058f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_058f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_058f:
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
.L_lambda_simple_env_loop_0590:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0590
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0590
.L_lambda_simple_env_end_0590:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0590:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0590
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0590
.L_lambda_simple_params_end_0590:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0590
	jmp .L_lambda_simple_end_0590
.L_lambda_simple_code_0590:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0590
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0590:
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
	jne .L_or_end_0063
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
	je .L_if_else_0426
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
.L_tc_recycle_frame_loop_0764:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0764
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0764
.L_tc_recycle_frame_done_0764:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0426

	.L_if_else_0426:
	mov rax, L_constants + 2

	.L_if_end_0426:
.L_or_end_0063:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0590:	; new closure is in rax

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
.L_lambda_opt_env_loop_00c1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_opt_env_end_00c1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00c1
.L_lambda_opt_env_end_00c1:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00c1:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00c1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00c1
.L_lambda_opt_params_end_00c1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00c1
	jmp .L_lambda_opt_end_00c1
.L_lambda_opt_code_00c1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00c1 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00c1 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00c1:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00c1:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00c1
	.L_lambda_opt_exact_shifting_loop_end_00c1:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00c1
	.L_lambda_opt_arity_check_more_00c1:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00c1
	.L_lambda_opt_stack_shrink_loop_00c1:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00c1:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00c1
	.L_lambda_opt_more_shifting_loop_end_00c1:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_00c1
	.L_lambda_opt_stack_shrink_loop_exit_00c1:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00c1:
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
.L_tc_recycle_frame_loop_0765:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0765
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0765
.L_tc_recycle_frame_done_0765:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00c1:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_058f:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0766:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0766
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0766
.L_tc_recycle_frame_done_0766:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_058e:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0767:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0767
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0767
.L_tc_recycle_frame_done_0767:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_058a:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0768:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0768
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0768
.L_tc_recycle_frame_done_0768:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0589:	; new closure is in rax
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
.L_lambda_simple_env_loop_0591:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0591
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0591
.L_lambda_simple_env_end_0591:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0591:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0591
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0591
.L_lambda_simple_params_end_0591:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0591
	jmp .L_lambda_simple_end_0591
.L_lambda_simple_code_0591:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0591
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0591:
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
.L_lambda_simple_end_0591:	; new closure is in rax
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
.L_lambda_simple_env_loop_0592:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0592
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0592
.L_lambda_simple_env_end_0592:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0592:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0592
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0592
.L_lambda_simple_params_end_0592:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0592
	jmp .L_lambda_simple_end_0592
.L_lambda_simple_code_0592:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0592
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0592:
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
.L_lambda_simple_env_loop_0593:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0593
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0593
.L_lambda_simple_env_end_0593:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0593:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0593
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0593
.L_lambda_simple_params_end_0593:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0593
	jmp .L_lambda_simple_end_0593
.L_lambda_simple_code_0593:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0593
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0593:
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
.L_lambda_simple_env_loop_0594:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0594
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0594
.L_lambda_simple_env_end_0594:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0594:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0594
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0594
.L_lambda_simple_params_end_0594:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0594
	jmp .L_lambda_simple_end_0594
.L_lambda_simple_code_0594:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0594
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0594:
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
	jne .L_or_end_0064
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
	jne .L_or_end_0064
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
	je .L_if_else_0427
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
	je .L_if_else_0428
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
.L_tc_recycle_frame_loop_0769:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0769
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0769
.L_tc_recycle_frame_done_0769:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0428

	.L_if_else_0428:
	mov rax, L_constants + 2

	.L_if_end_0428:

	jmp .L_if_end_0427

	.L_if_else_0427:
	mov rax, L_constants + 2

	.L_if_end_0427:
.L_or_end_0064:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_0594:	; new closure is in rax

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
.L_lambda_simple_env_loop_0595:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0595
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0595
.L_lambda_simple_env_end_0595:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0595:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0595
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0595
.L_lambda_simple_params_end_0595:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0595
	jmp .L_lambda_simple_end_0595
.L_lambda_simple_code_0595:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0595
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0595:
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
.L_lambda_simple_env_loop_0596:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0596
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0596
.L_lambda_simple_env_end_0596:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0596:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0596
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0596
.L_lambda_simple_params_end_0596:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0596
	jmp .L_lambda_simple_end_0596
.L_lambda_simple_code_0596:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0596
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0596:
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
	je .L_if_else_0429
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
.L_tc_recycle_frame_loop_076a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_076a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_076a
.L_tc_recycle_frame_done_076a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0429

	.L_if_else_0429:
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
.L_tc_recycle_frame_loop_076b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_076b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_076b
.L_tc_recycle_frame_done_076b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_0429:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0596:	; new closure is in rax
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
.L_tc_recycle_frame_loop_076c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_076c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_076c
.L_tc_recycle_frame_done_076c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0595:	; new closure is in rax
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
.L_lambda_simple_env_loop_0597:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0597
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0597
.L_lambda_simple_env_end_0597:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0597:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0597
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0597
.L_lambda_simple_params_end_0597:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0597
	jmp .L_lambda_simple_end_0597
.L_lambda_simple_code_0597:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0597
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0597:
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
.L_lambda_simple_env_loop_0598:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_0598
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0598
.L_lambda_simple_env_end_0598:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0598:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0598
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0598
.L_lambda_simple_params_end_0598:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0598
	jmp .L_lambda_simple_end_0598
.L_lambda_simple_code_0598:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0598
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0598:
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
.L_lambda_simple_env_loop_0599:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_0599
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0599
.L_lambda_simple_env_end_0599:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0599:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0599
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0599
.L_lambda_simple_params_end_0599:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0599
	jmp .L_lambda_simple_end_0599
.L_lambda_simple_code_0599:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0599
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0599:
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
	jne .L_or_end_0065
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
	je .L_if_else_042a
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
.L_tc_recycle_frame_loop_076d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_076d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_076d
.L_tc_recycle_frame_done_076d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_042a

	.L_if_else_042a:
	mov rax, L_constants + 2

	.L_if_end_042a:
.L_or_end_0065:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0599:	; new closure is in rax

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
.L_lambda_opt_env_loop_00c2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_opt_env_end_00c2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00c2
.L_lambda_opt_env_end_00c2:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00c2:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00c2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00c2
.L_lambda_opt_params_end_00c2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00c2
	jmp .L_lambda_opt_end_00c2
.L_lambda_opt_code_00c2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00c2 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00c2 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00c2:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00c2:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00c2
	.L_lambda_opt_exact_shifting_loop_end_00c2:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00c2
	.L_lambda_opt_arity_check_more_00c2:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00c2
	.L_lambda_opt_stack_shrink_loop_00c2:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00c2:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00c2
	.L_lambda_opt_more_shifting_loop_end_00c2:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_00c2
	.L_lambda_opt_stack_shrink_loop_exit_00c2:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00c2:
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
.L_tc_recycle_frame_loop_076e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_076e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_076e
.L_tc_recycle_frame_done_076e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00c2:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0598:	; new closure is in rax
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
.L_tc_recycle_frame_loop_076f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_076f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_076f
.L_tc_recycle_frame_done_076f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0597:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0770:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0770
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0770
.L_tc_recycle_frame_done_0770:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0593:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0771:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0771
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0771
.L_tc_recycle_frame_done_0771:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0592:	; new closure is in rax
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
.L_lambda_simple_env_loop_059a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_059a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_059a
.L_lambda_simple_env_end_059a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_059a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_059a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_059a
.L_lambda_simple_params_end_059a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_059a
	jmp .L_lambda_simple_end_059a
.L_lambda_simple_code_059a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_059a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_059a:
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
.L_lambda_simple_end_059a:	; new closure is in rax
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
.L_lambda_simple_env_loop_059b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_059b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_059b
.L_lambda_simple_env_end_059b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_059b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_059b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_059b
.L_lambda_simple_params_end_059b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_059b
	jmp .L_lambda_simple_end_059b
.L_lambda_simple_code_059b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_059b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_059b:
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
.L_lambda_simple_env_loop_059c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_059c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_059c
.L_lambda_simple_env_end_059c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_059c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_059c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_059c
.L_lambda_simple_params_end_059c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_059c
	jmp .L_lambda_simple_end_059c
.L_lambda_simple_code_059c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_059c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_059c:
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
.L_lambda_simple_env_loop_059d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_059d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_059d
.L_lambda_simple_env_end_059d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_059d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_059d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_059d
.L_lambda_simple_params_end_059d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_059d
	jmp .L_lambda_simple_end_059d
.L_lambda_simple_code_059d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 4
	je .L_lambda_simple_arity_check_ok_059d
	push qword [rsp + 8 * 2]
	push 4
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_059d:
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
	jne .L_or_end_0066
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
	je .L_if_else_042b
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
	je .L_if_else_042c
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
.L_tc_recycle_frame_loop_0772:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0772
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0772
.L_tc_recycle_frame_done_0772:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_042c

	.L_if_else_042c:
	mov rax, L_constants + 2

	.L_if_end_042c:

	jmp .L_if_end_042b

	.L_if_else_042b:
	mov rax, L_constants + 2

	.L_if_end_042b:
.L_or_end_0066:
	leave
	ret AND_KILL_FRAME(4)
.L_lambda_simple_end_059d:	; new closure is in rax

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
.L_lambda_simple_env_loop_059e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_059e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_059e
.L_lambda_simple_env_end_059e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_059e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_059e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_059e
.L_lambda_simple_params_end_059e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_059e
	jmp .L_lambda_simple_end_059e
.L_lambda_simple_code_059e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_059e
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_059e:
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
.L_lambda_simple_env_loop_059f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_059f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_059f
.L_lambda_simple_env_end_059f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_059f:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_059f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_059f
.L_lambda_simple_params_end_059f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_059f
	jmp .L_lambda_simple_end_059f
.L_lambda_simple_code_059f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_059f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_059f:
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
	je .L_if_else_042d
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
.L_tc_recycle_frame_loop_0773:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0773
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0773
.L_tc_recycle_frame_done_0773:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_042d

	.L_if_else_042d:
	mov rax, L_constants + 2

	.L_if_end_042d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_059f:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0774:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0774
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0774
.L_tc_recycle_frame_done_0774:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_059e:	; new closure is in rax
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
.L_lambda_simple_env_loop_05a0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05a0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a0
.L_lambda_simple_env_end_05a0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05a0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a0
.L_lambda_simple_params_end_05a0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a0
	jmp .L_lambda_simple_end_05a0
.L_lambda_simple_code_05a0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05a0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a0:
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
.L_lambda_simple_env_loop_05a1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05a1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a1
.L_lambda_simple_env_end_05a1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05a1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a1
.L_lambda_simple_params_end_05a1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a1
	jmp .L_lambda_simple_end_05a1
.L_lambda_simple_code_05a1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05a1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a1:
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
.L_lambda_simple_env_loop_05a2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_05a2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a2
.L_lambda_simple_env_end_05a2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05a2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a2
.L_lambda_simple_params_end_05a2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a2
	jmp .L_lambda_simple_end_05a2
.L_lambda_simple_code_05a2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_05a2
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a2:
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
	jne .L_or_end_0067
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
	je .L_if_else_042e
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
.L_tc_recycle_frame_loop_0775:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0775
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0775
.L_tc_recycle_frame_done_0775:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_042e

	.L_if_else_042e:
	mov rax, L_constants + 2

	.L_if_end_042e:
.L_or_end_0067:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_05a2:	; new closure is in rax

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
.L_lambda_opt_env_loop_00c3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_opt_env_end_00c3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00c3
.L_lambda_opt_env_end_00c3:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00c3:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00c3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00c3
.L_lambda_opt_params_end_00c3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00c3
	jmp .L_lambda_opt_end_00c3
.L_lambda_opt_code_00c3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00c3 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00c3 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00c3:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00c3:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00c3
	.L_lambda_opt_exact_shifting_loop_end_00c3:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00c3
	.L_lambda_opt_arity_check_more_00c3:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00c3
	.L_lambda_opt_stack_shrink_loop_00c3:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00c3:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00c3
	.L_lambda_opt_more_shifting_loop_end_00c3:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_00c3
	.L_lambda_opt_stack_shrink_loop_exit_00c3:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00c3:
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
.L_tc_recycle_frame_loop_0776:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0776
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0776
.L_tc_recycle_frame_done_0776:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00c3:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05a1:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0777:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0777
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0777
.L_tc_recycle_frame_done_0777:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05a0:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0778:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0778
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0778
.L_tc_recycle_frame_done_0778:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_059c:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0779:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0779
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0779
.L_tc_recycle_frame_done_0779:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_059b:	; new closure is in rax
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
.L_lambda_simple_env_loop_05a3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05a3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a3
.L_lambda_simple_env_end_05a3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05a3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a3
.L_lambda_simple_params_end_05a3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a3
	jmp .L_lambda_simple_end_05a3
.L_lambda_simple_code_05a3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05a3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a3:
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
.L_lambda_simple_end_05a3:	; new closure is in rax
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
.L_lambda_simple_env_loop_05a4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05a4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a4
.L_lambda_simple_env_end_05a4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05a4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a4
.L_lambda_simple_params_end_05a4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a4
	jmp .L_lambda_simple_end_05a4
.L_lambda_simple_code_05a4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05a4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a4:
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
	je .L_if_else_042f
	mov rax, L_constants + 2023

	jmp .L_if_end_042f

	.L_if_else_042f:
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
.L_tc_recycle_frame_loop_077a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_077a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_077a
.L_tc_recycle_frame_done_077a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_042f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05a4:	; new closure is in rax
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
.L_lambda_simple_env_loop_05a5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05a5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a5
.L_lambda_simple_env_end_05a5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05a5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a5
.L_lambda_simple_params_end_05a5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a5
	jmp .L_lambda_simple_end_05a5
.L_lambda_simple_code_05a5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05a5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a5:
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
	jne .L_or_end_0068
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
	je .L_if_else_0430
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
.L_tc_recycle_frame_loop_077b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_077b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_077b
.L_tc_recycle_frame_done_077b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0430

	.L_if_else_0430:
	mov rax, L_constants + 2

	.L_if_end_0430:
.L_or_end_0068:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05a5:	; new closure is in rax
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
.L_lambda_simple_env_loop_05a6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05a6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a6
.L_lambda_simple_env_end_05a6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05a6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a6
.L_lambda_simple_params_end_05a6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a6
	jmp .L_lambda_simple_end_05a6
.L_lambda_simple_code_05a6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05a6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a6:
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
.L_lambda_opt_env_loop_00c4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00c4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00c4
.L_lambda_opt_env_end_00c4:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00c4:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00c4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00c4
.L_lambda_opt_params_end_00c4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00c4
	jmp .L_lambda_opt_end_00c4
.L_lambda_opt_code_00c4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00c4 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00c4 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00c4:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00c4:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00c4
	.L_lambda_opt_exact_shifting_loop_end_00c4:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00c4
	.L_lambda_opt_arity_check_more_00c4:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00c4
	.L_lambda_opt_stack_shrink_loop_00c4:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00c4:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00c4
	.L_lambda_opt_more_shifting_loop_end_00c4:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_00c4
	.L_lambda_opt_stack_shrink_loop_exit_00c4:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00c4:
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
	je .L_if_else_0431
	mov rax, L_constants + 0

	jmp .L_if_end_0431

	.L_if_else_0431:
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
	je .L_if_else_0433
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

	jmp .L_if_end_0433

	.L_if_else_0433:
	mov rax, L_constants + 2

	.L_if_end_0433:

	cmp rax, sob_boolean_false
	je .L_if_else_0432
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

	jmp .L_if_end_0432

	.L_if_else_0432:
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

	.L_if_end_0432:

	.L_if_end_0431:
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
.L_lambda_simple_env_loop_05a7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05a7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a7
.L_lambda_simple_env_end_05a7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a7:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_05a7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a7
.L_lambda_simple_params_end_05a7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a7
	jmp .L_lambda_simple_end_05a7
.L_lambda_simple_code_05a7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05a7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a7:
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
.L_tc_recycle_frame_loop_077c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_077c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_077c
.L_tc_recycle_frame_done_077c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05a7:	; new closure is in rax
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
.L_tc_recycle_frame_loop_077d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_077d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_077d
.L_tc_recycle_frame_done_077d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00c4:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05a6:	; new closure is in rax
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
.L_lambda_simple_env_loop_05a8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05a8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a8
.L_lambda_simple_env_end_05a8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05a8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a8
.L_lambda_simple_params_end_05a8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a8
	jmp .L_lambda_simple_end_05a8
.L_lambda_simple_code_05a8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05a8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a8:
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
.L_lambda_opt_env_loop_00c5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00c5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00c5
.L_lambda_opt_env_end_00c5:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00c5:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_00c5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00c5
.L_lambda_opt_params_end_00c5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00c5
	jmp .L_lambda_opt_end_00c5
.L_lambda_opt_code_00c5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00c5 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00c5 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 1
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00c5:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00c5:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00c5
	.L_lambda_opt_exact_shifting_loop_end_00c5:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00c5
	.L_lambda_opt_arity_check_more_00c5:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 2;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00c5
	.L_lambda_opt_stack_shrink_loop_00c5:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00c5:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00c5
	.L_lambda_opt_more_shifting_loop_end_00c5:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_stack_shrink_loop_00c5
	.L_lambda_opt_stack_shrink_loop_exit_00c5:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00c5:
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
	je .L_if_else_0434
	mov rax, L_constants + 4

	jmp .L_if_end_0434

	.L_if_else_0434:
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
	je .L_if_else_0436
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

	jmp .L_if_end_0436

	.L_if_else_0436:
	mov rax, L_constants + 2

	.L_if_end_0436:

	cmp rax, sob_boolean_false
	je .L_if_else_0435
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

	jmp .L_if_end_0435

	.L_if_else_0435:
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

	.L_if_end_0435:

	.L_if_end_0434:
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
.L_lambda_simple_env_loop_05a9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05a9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05a9
.L_lambda_simple_env_end_05a9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05a9:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_05a9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05a9
.L_lambda_simple_params_end_05a9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05a9
	jmp .L_lambda_simple_end_05a9
.L_lambda_simple_code_05a9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05a9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05a9:
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
.L_tc_recycle_frame_loop_077e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_077e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_077e
.L_tc_recycle_frame_done_077e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05a9:	; new closure is in rax
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
.L_tc_recycle_frame_loop_077f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_077f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_077f
.L_tc_recycle_frame_done_077f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00c5:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05a8:	; new closure is in rax
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
.L_lambda_simple_env_loop_05aa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05aa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05aa
.L_lambda_simple_env_end_05aa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05aa:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05aa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05aa
.L_lambda_simple_params_end_05aa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05aa
	jmp .L_lambda_simple_end_05aa
.L_lambda_simple_code_05aa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05aa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05aa:
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
.L_lambda_simple_env_loop_05ab:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05ab
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ab
.L_lambda_simple_env_end_05ab:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ab:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05ab
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ab
.L_lambda_simple_params_end_05ab:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ab
	jmp .L_lambda_simple_end_05ab
.L_lambda_simple_code_05ab:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_05ab
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ab:
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
	je .L_if_else_0437
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
.L_tc_recycle_frame_loop_0780:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0780
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0780
.L_tc_recycle_frame_done_0780:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0437

	.L_if_else_0437:
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
.L_lambda_simple_env_loop_05ac:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05ac
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ac
.L_lambda_simple_env_end_05ac:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ac:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_05ac
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ac
.L_lambda_simple_params_end_05ac:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ac
	jmp .L_lambda_simple_end_05ac
.L_lambda_simple_code_05ac:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ac
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ac:
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
.L_lambda_simple_end_05ac:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0781:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0781
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0781
.L_tc_recycle_frame_done_0781:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_0437:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_05ab:	; new closure is in rax

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
.L_lambda_simple_env_loop_05ad:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05ad
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ad
.L_lambda_simple_env_end_05ad:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ad:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05ad
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ad
.L_lambda_simple_params_end_05ad:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ad
	jmp .L_lambda_simple_end_05ad
.L_lambda_simple_code_05ad:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ad
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ad:
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
.L_tc_recycle_frame_loop_0782:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0782
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0782
.L_tc_recycle_frame_done_0782:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ad:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05aa:	; new closure is in rax
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
.L_lambda_simple_env_loop_05ae:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05ae
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ae
.L_lambda_simple_env_end_05ae:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ae:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05ae
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ae
.L_lambda_simple_params_end_05ae:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ae
	jmp .L_lambda_simple_end_05ae
.L_lambda_simple_code_05ae:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ae
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ae:
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
.L_lambda_simple_env_loop_05af:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05af
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05af
.L_lambda_simple_env_end_05af:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05af:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05af
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05af
.L_lambda_simple_params_end_05af:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05af
	jmp .L_lambda_simple_end_05af
.L_lambda_simple_code_05af:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_05af
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05af:
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
	je .L_if_else_0438
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
.L_tc_recycle_frame_loop_0783:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0783
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0783
.L_tc_recycle_frame_done_0783:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0438

	.L_if_else_0438:
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
.L_lambda_simple_env_loop_05b0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05b0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b0
.L_lambda_simple_env_end_05b0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b0:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_05b0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b0
.L_lambda_simple_params_end_05b0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b0
	jmp .L_lambda_simple_end_05b0
.L_lambda_simple_code_05b0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05b0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b0:
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
.L_lambda_simple_end_05b0:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0784:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0784
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0784
.L_tc_recycle_frame_done_0784:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_0438:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_05af:	; new closure is in rax

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
.L_lambda_simple_env_loop_05b1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05b1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b1
.L_lambda_simple_env_end_05b1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05b1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b1
.L_lambda_simple_params_end_05b1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b1
	jmp .L_lambda_simple_end_05b1
.L_lambda_simple_code_05b1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05b1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b1:
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
.L_tc_recycle_frame_loop_0785:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0785
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0785
.L_tc_recycle_frame_done_0785:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05b1:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ae:	; new closure is in rax
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
.L_lambda_opt_env_loop_00c6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_00c6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00c6
.L_lambda_opt_env_end_00c6:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00c6:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_00c6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00c6
.L_lambda_opt_params_end_00c6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00c6
	jmp .L_lambda_opt_end_00c6
.L_lambda_opt_code_00c6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00c6 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00c6 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00c6:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00c6:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00c6
	.L_lambda_opt_exact_shifting_loop_end_00c6:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00c6
	.L_lambda_opt_arity_check_more_00c6:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00c6
	.L_lambda_opt_stack_shrink_loop_00c6:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00c6:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00c6
	.L_lambda_opt_more_shifting_loop_end_00c6:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_00c6
	.L_lambda_opt_stack_shrink_loop_exit_00c6:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00c6:
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
.L_tc_recycle_frame_loop_0786:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0786
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0786
.L_tc_recycle_frame_done_0786:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00c6:	; new closure is in rax
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
.L_lambda_simple_env_loop_05b2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05b2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b2
.L_lambda_simple_env_end_05b2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b2:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05b2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b2
.L_lambda_simple_params_end_05b2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b2
	jmp .L_lambda_simple_end_05b2
.L_lambda_simple_code_05b2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05b2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b2:
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
.L_lambda_simple_env_loop_05b3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05b3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b3
.L_lambda_simple_env_end_05b3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05b3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b3
.L_lambda_simple_params_end_05b3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b3
	jmp .L_lambda_simple_end_05b3
.L_lambda_simple_code_05b3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_05b3
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b3:
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
	je .L_if_else_0439
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
.L_tc_recycle_frame_loop_0787:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0787
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0787
.L_tc_recycle_frame_done_0787:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0439

	.L_if_else_0439:
	mov rax, L_constants + 1

	.L_if_end_0439:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_05b3:	; new closure is in rax

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
.L_lambda_simple_env_loop_05b4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05b4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b4
.L_lambda_simple_env_end_05b4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05b4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b4
.L_lambda_simple_params_end_05b4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b4
	jmp .L_lambda_simple_end_05b4
.L_lambda_simple_code_05b4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05b4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b4:
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
.L_tc_recycle_frame_loop_0788:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0788
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0788
.L_tc_recycle_frame_done_0788:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05b4:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05b2:	; new closure is in rax
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
.L_lambda_simple_env_loop_05b5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05b5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b5
.L_lambda_simple_env_end_05b5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05b5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b5
.L_lambda_simple_params_end_05b5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b5
	jmp .L_lambda_simple_end_05b5
.L_lambda_simple_code_05b5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05b5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b5:
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
.L_lambda_simple_env_loop_05b6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05b6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b6
.L_lambda_simple_env_end_05b6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05b6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b6
.L_lambda_simple_params_end_05b6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b6
	jmp .L_lambda_simple_end_05b6
.L_lambda_simple_code_05b6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_05b6
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b6:
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
	je .L_if_else_043a
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
.L_tc_recycle_frame_loop_0789:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0789
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0789
.L_tc_recycle_frame_done_0789:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_043a

	.L_if_else_043a:
	mov rax, L_constants + 1

	.L_if_end_043a:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_05b6:	; new closure is in rax

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
.L_lambda_simple_env_loop_05b7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05b7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b7
.L_lambda_simple_env_end_05b7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05b7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b7
.L_lambda_simple_params_end_05b7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b7
	jmp .L_lambda_simple_end_05b7
.L_lambda_simple_code_05b7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05b7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b7:
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
.L_tc_recycle_frame_loop_078a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_078a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_078a
.L_tc_recycle_frame_done_078a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05b7:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05b5:	; new closure is in rax
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
.L_lambda_simple_env_loop_05b8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05b8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b8
.L_lambda_simple_env_end_05b8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05b8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b8
.L_lambda_simple_params_end_05b8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b8
	jmp .L_lambda_simple_end_05b8
.L_lambda_simple_code_05b8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05b8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b8:
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
.L_tc_recycle_frame_loop_078b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_078b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_078b
.L_tc_recycle_frame_done_078b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05b8:	; new closure is in rax
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
.L_lambda_simple_env_loop_05b9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05b9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05b9
.L_lambda_simple_env_end_05b9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05b9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05b9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05b9
.L_lambda_simple_params_end_05b9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05b9
	jmp .L_lambda_simple_end_05b9
.L_lambda_simple_code_05b9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05b9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05b9:
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
.L_tc_recycle_frame_loop_078c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_078c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_078c
.L_tc_recycle_frame_done_078c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05b9:	; new closure is in rax
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
.L_lambda_simple_env_loop_05ba:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05ba
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ba
.L_lambda_simple_env_end_05ba:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ba:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05ba
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ba
.L_lambda_simple_params_end_05ba:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ba
	jmp .L_lambda_simple_end_05ba
.L_lambda_simple_code_05ba:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ba
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ba:
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
.L_tc_recycle_frame_loop_078d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_078d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_078d
.L_tc_recycle_frame_done_078d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ba:	; new closure is in rax
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
.L_lambda_simple_env_loop_05bb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05bb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05bb
.L_lambda_simple_env_end_05bb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05bb:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05bb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05bb
.L_lambda_simple_params_end_05bb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05bb
	jmp .L_lambda_simple_end_05bb
.L_lambda_simple_code_05bb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05bb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05bb:
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
.L_tc_recycle_frame_loop_078e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_078e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_078e
.L_tc_recycle_frame_done_078e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05bb:	; new closure is in rax
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
.L_lambda_simple_env_loop_05bc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05bc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05bc
.L_lambda_simple_env_end_05bc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05bc:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05bc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05bc
.L_lambda_simple_params_end_05bc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05bc
	jmp .L_lambda_simple_end_05bc
.L_lambda_simple_code_05bc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05bc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05bc:
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
.L_tc_recycle_frame_loop_078f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_078f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_078f
.L_tc_recycle_frame_done_078f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05bc:	; new closure is in rax
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
.L_lambda_simple_env_loop_05bd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05bd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05bd
.L_lambda_simple_env_end_05bd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05bd:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05bd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05bd
.L_lambda_simple_params_end_05bd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05bd
	jmp .L_lambda_simple_end_05bd
.L_lambda_simple_code_05bd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05bd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05bd:
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
	je .L_if_else_043b
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
.L_tc_recycle_frame_loop_0790:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0790
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0790
.L_tc_recycle_frame_done_0790:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_043b

	.L_if_else_043b:
	mov rax, PARAM(0)	; param x

	.L_if_end_043b:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05bd:	; new closure is in rax
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
.L_lambda_simple_env_loop_05be:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05be
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05be
.L_lambda_simple_env_end_05be:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05be:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05be
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05be
.L_lambda_simple_params_end_05be:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05be
	jmp .L_lambda_simple_end_05be
.L_lambda_simple_code_05be:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_05be
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05be:
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
	je .L_if_else_043d
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

	jmp .L_if_end_043d

	.L_if_else_043d:
	mov rax, L_constants + 2

	.L_if_end_043d:

	cmp rax, sob_boolean_false
	je .L_if_else_043c
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
	je .L_if_else_043e
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
.L_tc_recycle_frame_loop_0791:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0791
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0791
.L_tc_recycle_frame_done_0791:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_043e

	.L_if_else_043e:
	mov rax, L_constants + 2

	.L_if_end_043e:

	jmp .L_if_end_043c

	.L_if_else_043c:
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
	je .L_if_else_0440
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
	je .L_if_else_0441
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

	jmp .L_if_end_0441

	.L_if_else_0441:
	mov rax, L_constants + 2

	.L_if_end_0441:

	jmp .L_if_end_0440

	.L_if_else_0440:
	mov rax, L_constants + 2

	.L_if_end_0440:

	cmp rax, sob_boolean_false
	je .L_if_else_043f
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
.L_tc_recycle_frame_loop_0792:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0792
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0792
.L_tc_recycle_frame_done_0792:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_043f

	.L_if_else_043f:
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
	je .L_if_else_0443
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
	je .L_if_else_0444
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

	jmp .L_if_end_0444

	.L_if_else_0444:
	mov rax, L_constants + 2

	.L_if_end_0444:

	jmp .L_if_end_0443

	.L_if_else_0443:
	mov rax, L_constants + 2

	.L_if_end_0443:

	cmp rax, sob_boolean_false
	je .L_if_else_0442
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
.L_tc_recycle_frame_loop_0793:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0793
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0793
.L_tc_recycle_frame_done_0793:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0442

	.L_if_else_0442:
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
	je .L_if_else_0446
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

	jmp .L_if_end_0446

	.L_if_else_0446:
	mov rax, L_constants + 2

	.L_if_end_0446:

	cmp rax, sob_boolean_false
	je .L_if_else_0445
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
.L_tc_recycle_frame_loop_0794:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0794
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0794
.L_tc_recycle_frame_done_0794:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0445

	.L_if_else_0445:
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
	je .L_if_else_0448
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

	jmp .L_if_end_0448

	.L_if_else_0448:
	mov rax, L_constants + 2

	.L_if_end_0448:

	cmp rax, sob_boolean_false
	je .L_if_else_0447
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
.L_tc_recycle_frame_loop_0795:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0795
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0795
.L_tc_recycle_frame_done_0795:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0447

	.L_if_else_0447:
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
.L_tc_recycle_frame_loop_0796:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0796
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0796
.L_tc_recycle_frame_done_0796:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_0447:

	.L_if_end_0445:

	.L_if_end_0442:

	.L_if_end_043f:

	.L_if_end_043c:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_05be:	; new closure is in rax
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
.L_lambda_simple_env_loop_05bf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05bf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05bf
.L_lambda_simple_env_end_05bf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05bf:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05bf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05bf
.L_lambda_simple_params_end_05bf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05bf
	jmp .L_lambda_simple_end_05bf
.L_lambda_simple_code_05bf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_05bf
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05bf:
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
	je .L_if_else_0449
	mov rax, L_constants + 2

	jmp .L_if_end_0449

	.L_if_else_0449:
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
	je .L_if_else_044a
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
.L_tc_recycle_frame_loop_0797:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0797
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0797
.L_tc_recycle_frame_done_0797:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_044a

	.L_if_else_044a:
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
.L_tc_recycle_frame_loop_0798:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0798
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0798
.L_tc_recycle_frame_done_0798:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_044a:

	.L_if_end_0449:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_05bf:	; new closure is in rax
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
.L_lambda_simple_env_loop_05c0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05c0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c0
.L_lambda_simple_env_end_05c0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05c0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c0
.L_lambda_simple_params_end_05c0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c0
	jmp .L_lambda_simple_end_05c0
.L_lambda_simple_code_05c0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_05c0
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c0:
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
.L_lambda_simple_env_loop_05c1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05c1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c1
.L_lambda_simple_env_end_05c1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c1:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_05c1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c1
.L_lambda_simple_params_end_05c1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c1
	jmp .L_lambda_simple_end_05c1
.L_lambda_simple_code_05c1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_05c1
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c1:
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
	je .L_if_else_044b
	mov rax, PARAM(0)	; param target

	jmp .L_if_end_044b

	.L_if_else_044b:
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
.L_lambda_simple_env_loop_05c2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05c2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c2
.L_lambda_simple_env_end_05c2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c2:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_05c2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c2
.L_lambda_simple_params_end_05c2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c2
	jmp .L_lambda_simple_end_05c2
.L_lambda_simple_code_05c2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05c2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c2:
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
.L_tc_recycle_frame_loop_0799:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0799
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0799
.L_tc_recycle_frame_done_0799:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05c2:	; new closure is in rax
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
.L_tc_recycle_frame_loop_079a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_079a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_079a
.L_tc_recycle_frame_done_079a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_044b:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_05c1:	; new closure is in rax

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
.L_lambda_simple_env_loop_05c3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05c3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c3
.L_lambda_simple_env_end_05c3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c3:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_05c3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c3
.L_lambda_simple_params_end_05c3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c3
	jmp .L_lambda_simple_end_05c3
.L_lambda_simple_code_05c3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_05c3
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c3:
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
	je .L_if_else_044c
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
.L_tc_recycle_frame_loop_079b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_079b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_079b
.L_tc_recycle_frame_done_079b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_044c

	.L_if_else_044c:
	mov rax, PARAM(1)	; param i

	.L_if_end_044c:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_05c3:	; new closure is in rax

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
.L_lambda_opt_env_loop_00c7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00c7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00c7
.L_lambda_opt_env_end_00c7:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00c7:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_00c7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00c7
.L_lambda_opt_params_end_00c7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00c7
	jmp .L_lambda_opt_end_00c7
.L_lambda_opt_code_00c7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00c7 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00c7 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00c7:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00c7:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00c7
	.L_lambda_opt_exact_shifting_loop_end_00c7:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00c7
	.L_lambda_opt_arity_check_more_00c7:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00c7
	.L_lambda_opt_stack_shrink_loop_00c7:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00c7:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00c7
	.L_lambda_opt_more_shifting_loop_end_00c7:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_00c7
	.L_lambda_opt_stack_shrink_loop_exit_00c7:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00c7:
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
.L_tc_recycle_frame_loop_079c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_079c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_079c
.L_tc_recycle_frame_done_079c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00c7:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_05c0:	; new closure is in rax
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
.L_lambda_simple_env_loop_05c4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05c4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c4
.L_lambda_simple_env_end_05c4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05c4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c4
.L_lambda_simple_params_end_05c4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c4
	jmp .L_lambda_simple_end_05c4
.L_lambda_simple_code_05c4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_05c4
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c4:
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
.L_lambda_simple_env_loop_05c5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05c5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c5
.L_lambda_simple_env_end_05c5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c5:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_05c5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c5
.L_lambda_simple_params_end_05c5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c5
	jmp .L_lambda_simple_end_05c5
.L_lambda_simple_code_05c5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_05c5
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c5:
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
	je .L_if_else_044d
	mov rax, PARAM(0)	; param target

	jmp .L_if_end_044d

	.L_if_else_044d:
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
.L_lambda_simple_env_loop_05c6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05c6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c6
.L_lambda_simple_env_end_05c6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c6:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_05c6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c6
.L_lambda_simple_params_end_05c6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c6
	jmp .L_lambda_simple_end_05c6
.L_lambda_simple_code_05c6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05c6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c6:
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
.L_tc_recycle_frame_loop_079d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_079d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_079d
.L_tc_recycle_frame_done_079d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05c6:	; new closure is in rax
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
.L_tc_recycle_frame_loop_079e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_079e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_079e
.L_tc_recycle_frame_done_079e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_044d:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_05c5:	; new closure is in rax

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
.L_lambda_simple_env_loop_05c7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05c7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c7
.L_lambda_simple_env_end_05c7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c7:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_05c7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c7
.L_lambda_simple_params_end_05c7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c7
	jmp .L_lambda_simple_end_05c7
.L_lambda_simple_code_05c7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_05c7
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c7:
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
	je .L_if_else_044e
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
.L_tc_recycle_frame_loop_079f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_079f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_079f
.L_tc_recycle_frame_done_079f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_044e

	.L_if_else_044e:
	mov rax, PARAM(1)	; param i

	.L_if_end_044e:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_05c7:	; new closure is in rax

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
.L_lambda_opt_env_loop_00c8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_00c8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_00c8
.L_lambda_opt_env_end_00c8:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_00c8:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_00c8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_00c8
.L_lambda_opt_params_end_00c8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_00c8
	jmp .L_lambda_opt_end_00c8
.L_lambda_opt_code_00c8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0 ;	 check num of args
	je .L_lambda_opt_arity_check_exact_00c8 ;	 if equal, go to exact arity
	jg .L_lambda_opt_arity_check_more_00c8 ;	 if greater than, go to arity more
	push qword [rsp + 8 * 2] ;	 else, throw opt erity error
 	push 0
	jmp L_error_incorrect_arity_opt
	.L_lambda_opt_arity_check_exact_00c8:
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time
	lea rbx, [rsp + 8 * (2 + rax)] ;	 rbx holds address of last element
	sub rsp, 8
	lea rcx, [rsp + 8 * 0] ;	 rcx holds address of first element
	.L_lambda_opt_exact_shifting_loop_00c8:
	mov rdx, [rcx + 8]
	mov [rcx], rdx
	add rcx, 8
	cmp rbx, rcx
	jne .L_lambda_opt_exact_shifting_loop_00c8
	.L_lambda_opt_exact_shifting_loop_end_00c8:
	mov qword[rbx], sob_nil ;	 place nil into address of last slot
	add rax, 1 ; 	arg count += 1
	mov qword [rsp + 8 * 2], rax
	jmp .L_lambda_opt_stack_adjusted_00c8
	.L_lambda_opt_arity_check_more_00c8:
	mov rdx, sob_nil ;	 () is the base cdr for the list
	cmp qword [rsp + 8 * 2], 1;	 compare count to params
	je .L_lambda_opt_stack_shrink_loop_exit_00c8
	.L_lambda_opt_stack_shrink_loop_00c8:
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	 mov rdx, rax ;	 list address is in rdx
	mov rax, qword [rsp + 8 * 2] ;	 number of argument in run time 
	mov rbx, qword [rsp + 8 * (2 + rax)] ;	 in rbx, the value of the last argument
 	mov SOB_PAIR_CAR(rdx) , rbx ;	 place the value in the car of the pair
	lea rbx, [rsp + 8 * (2 + rax - 1)] ;	 in rbx, the address of the one before last (rbx is the inner loop's index!)
	.L_lambda_opt_more_shifting_loop_00c8:
	mov rcx, [rbx] ;	 in rcx the value of the one before last
	mov [rbx + 8], rcx ;	 put the value of one before last, in last position
	sub rbx, 8 
	cmp rsp, rbx
	jle .L_lambda_opt_more_shifting_loop_00c8
	.L_lambda_opt_more_shifting_loop_end_00c8:
	add rsp, 8 ;	 update rsp
	mov rbx, [rsp + 8 * 2]
	sub rbx, 1 ;	 Subtract 1 from the register
	mov [rsp + 8 * 2], rbx ;	 Store the result back to memory
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_stack_shrink_loop_00c8
	.L_lambda_opt_stack_shrink_loop_exit_00c8:
	mov rcx, qword [rsp + 8 * 2] ;	 number of argument in run time
	mov rbx, qword [rsp + 8 * (2 + rcx)] ;	 in rbx, the value of the last argument
	mov rdi, (1 + 8 + 8) ;	 SOB PAIR
	call malloc ;	 allocated memory for the optional scheme list
	mov byte[rax], T_pair ;	 set type pair
	mov SOB_PAIR_CDR(rax), rdx ;	 set the cdr to the to curr cdr
	mov SOB_PAIR_CAR(rax) , rbx
	mov qword [rsp + 8 * (2 + rcx)], rax
	.L_lambda_opt_stack_adjusted_00c8:
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
.L_tc_recycle_frame_loop_07a0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07a0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07a0
.L_tc_recycle_frame_done_07a0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00c8:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_05c4:	; new closure is in rax
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
.L_lambda_simple_env_loop_05c8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05c8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c8
.L_lambda_simple_env_end_05c8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05c8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c8
.L_lambda_simple_params_end_05c8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c8
	jmp .L_lambda_simple_end_05c8
.L_lambda_simple_code_05c8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05c8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c8:
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
.L_tc_recycle_frame_loop_07a1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07a1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07a1
.L_tc_recycle_frame_done_07a1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05c8:	; new closure is in rax
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
.L_lambda_simple_env_loop_05c9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05c9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05c9
.L_lambda_simple_env_end_05c9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05c9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05c9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05c9
.L_lambda_simple_params_end_05c9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05c9
	jmp .L_lambda_simple_end_05c9
.L_lambda_simple_code_05c9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05c9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05c9:
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
.L_tc_recycle_frame_loop_07a2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07a2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07a2
.L_tc_recycle_frame_done_07a2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05c9:	; new closure is in rax
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
.L_lambda_simple_env_loop_05ca:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05ca
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ca
.L_lambda_simple_env_end_05ca:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ca:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05ca
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ca
.L_lambda_simple_params_end_05ca:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ca
	jmp .L_lambda_simple_end_05ca
.L_lambda_simple_code_05ca:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ca
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ca:
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
.L_lambda_simple_env_loop_05cb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05cb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05cb
.L_lambda_simple_env_end_05cb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05cb:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05cb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05cb
.L_lambda_simple_params_end_05cb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05cb
	jmp .L_lambda_simple_end_05cb
.L_lambda_simple_code_05cb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_05cb
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05cb:
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
	je .L_if_else_044f
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
.L_lambda_simple_env_loop_05cc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05cc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05cc
.L_lambda_simple_env_end_05cc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05cc:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_05cc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05cc
.L_lambda_simple_params_end_05cc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05cc
	jmp .L_lambda_simple_end_05cc
.L_lambda_simple_code_05cc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05cc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05cc:
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
.L_tc_recycle_frame_loop_07a3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07a3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07a3
.L_tc_recycle_frame_done_07a3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05cc:	; new closure is in rax
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
.L_tc_recycle_frame_loop_07a4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07a4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07a4
.L_tc_recycle_frame_done_07a4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_044f

	.L_if_else_044f:
	mov rax, PARAM(0)	; param str

	.L_if_end_044f:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_05cb:	; new closure is in rax

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
.L_lambda_simple_env_loop_05cd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05cd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05cd
.L_lambda_simple_env_end_05cd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05cd:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05cd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05cd
.L_lambda_simple_params_end_05cd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05cd
	jmp .L_lambda_simple_end_05cd
.L_lambda_simple_code_05cd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05cd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05cd:
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
.L_lambda_simple_env_loop_05ce:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05ce
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05ce
.L_lambda_simple_env_end_05ce:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05ce:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05ce
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05ce
.L_lambda_simple_params_end_05ce:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05ce
	jmp .L_lambda_simple_end_05ce
.L_lambda_simple_code_05ce:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05ce
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05ce:
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
	je .L_if_else_0450
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str

	jmp .L_if_end_0450

	.L_if_else_0450:
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
.L_tc_recycle_frame_loop_07a5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07a5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07a5
.L_tc_recycle_frame_done_07a5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_0450:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ce:	; new closure is in rax
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
.L_tc_recycle_frame_loop_07a6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07a6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07a6
.L_tc_recycle_frame_done_07a6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05cd:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05ca:	; new closure is in rax
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
.L_lambda_simple_env_loop_05cf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05cf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05cf
.L_lambda_simple_env_end_05cf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05cf:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05cf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05cf
.L_lambda_simple_params_end_05cf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05cf
	jmp .L_lambda_simple_end_05cf
.L_lambda_simple_code_05cf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05cf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05cf:
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
.L_lambda_simple_env_loop_05d0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05d0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d0
.L_lambda_simple_env_end_05d0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d0:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05d0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d0
.L_lambda_simple_params_end_05d0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d0
	jmp .L_lambda_simple_end_05d0
.L_lambda_simple_code_05d0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_05d0
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d0:
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
	je .L_if_else_0451
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
.L_lambda_simple_env_loop_05d1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05d1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d1
.L_lambda_simple_env_end_05d1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d1:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_05d1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d1
.L_lambda_simple_params_end_05d1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d1
	jmp .L_lambda_simple_end_05d1
.L_lambda_simple_code_05d1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d1:
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
.L_tc_recycle_frame_loop_07a7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07a7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07a7
.L_tc_recycle_frame_done_07a7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d1:	; new closure is in rax
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
.L_tc_recycle_frame_loop_07a8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07a8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07a8
.L_tc_recycle_frame_done_07a8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0451

	.L_if_else_0451:
	mov rax, PARAM(0)	; param vec

	.L_if_end_0451:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_05d0:	; new closure is in rax

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
.L_lambda_simple_env_loop_05d2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05d2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d2
.L_lambda_simple_env_end_05d2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05d2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d2
.L_lambda_simple_params_end_05d2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d2
	jmp .L_lambda_simple_end_05d2
.L_lambda_simple_code_05d2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d2:
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
.L_lambda_simple_env_loop_05d3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05d3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d3
.L_lambda_simple_env_end_05d3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05d3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d3
.L_lambda_simple_params_end_05d3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d3
	jmp .L_lambda_simple_end_05d3
.L_lambda_simple_code_05d3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d3:
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
	je .L_if_else_0452
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec

	jmp .L_if_end_0452

	.L_if_else_0452:
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
.L_tc_recycle_frame_loop_07a9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07a9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07a9
.L_tc_recycle_frame_done_07a9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_0452:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d3:	; new closure is in rax
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
.L_tc_recycle_frame_loop_07aa:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07aa
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07aa
.L_tc_recycle_frame_done_07aa:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d2:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05cf:	; new closure is in rax
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
.L_lambda_simple_env_loop_05d4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05d4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d4
.L_lambda_simple_env_end_05d4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05d4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d4
.L_lambda_simple_params_end_05d4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d4
	jmp .L_lambda_simple_end_05d4
.L_lambda_simple_code_05d4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_05d4
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d4:
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
.L_lambda_simple_env_loop_05d5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05d5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d5
.L_lambda_simple_env_end_05d5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d5:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_05d5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d5
.L_lambda_simple_params_end_05d5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d5
	jmp .L_lambda_simple_end_05d5
.L_lambda_simple_code_05d5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d5:
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
.L_lambda_simple_env_loop_05d6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05d6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d6
.L_lambda_simple_env_end_05d6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05d6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d6
.L_lambda_simple_params_end_05d6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d6
	jmp .L_lambda_simple_end_05d6
.L_lambda_simple_code_05d6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d6:
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
	je .L_if_else_0453
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
.L_tc_recycle_frame_loop_07ab:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07ab
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07ab
.L_tc_recycle_frame_done_07ab:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0453

	.L_if_else_0453:
	mov rax, L_constants + 1

	.L_if_end_0453:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d6:	; new closure is in rax

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
.L_tc_recycle_frame_loop_07ac:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07ac
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07ac
.L_tc_recycle_frame_done_07ac:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d5:	; new closure is in rax
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
.L_tc_recycle_frame_loop_07ad:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07ad
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07ad
.L_tc_recycle_frame_done_07ad:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_05d4:	; new closure is in rax
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
.L_lambda_simple_env_loop_05d7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05d7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d7
.L_lambda_simple_env_end_05d7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05d7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d7
.L_lambda_simple_params_end_05d7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d7
	jmp .L_lambda_simple_end_05d7
.L_lambda_simple_code_05d7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_05d7
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d7:
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
.L_lambda_simple_env_loop_05d8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05d8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d8
.L_lambda_simple_env_end_05d8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d8:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_05d8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d8
.L_lambda_simple_params_end_05d8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d8
	jmp .L_lambda_simple_end_05d8
.L_lambda_simple_code_05d8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d8:
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
.L_lambda_simple_env_loop_05d9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05d9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05d9
.L_lambda_simple_env_end_05d9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05d9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05d9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05d9
.L_lambda_simple_params_end_05d9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05d9
	jmp .L_lambda_simple_end_05d9
.L_lambda_simple_code_05d9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05d9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05d9:
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
.L_lambda_simple_env_loop_05da:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05da
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05da
.L_lambda_simple_env_end_05da:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05da:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05da
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05da
.L_lambda_simple_params_end_05da:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05da
	jmp .L_lambda_simple_end_05da
.L_lambda_simple_code_05da:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05da
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05da:
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
	je .L_if_else_0454
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
.L_tc_recycle_frame_loop_07ae:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07ae
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07ae
.L_tc_recycle_frame_done_07ae:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0454

	.L_if_else_0454:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str

	.L_if_end_0454:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05da:	; new closure is in rax

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
.L_tc_recycle_frame_loop_07af:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07af
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07af
.L_tc_recycle_frame_done_07af:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d9:	; new closure is in rax
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
.L_tc_recycle_frame_loop_07b0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07b0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07b0
.L_tc_recycle_frame_done_07b0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05d8:	; new closure is in rax
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
.L_tc_recycle_frame_loop_07b1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07b1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07b1
.L_tc_recycle_frame_done_07b1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_05d7:	; new closure is in rax
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
.L_lambda_simple_env_loop_05db:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05db
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05db
.L_lambda_simple_env_end_05db:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05db:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05db
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05db
.L_lambda_simple_params_end_05db:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05db
	jmp .L_lambda_simple_end_05db
.L_lambda_simple_code_05db:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_05db
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05db:
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
.L_lambda_simple_env_loop_05dc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_05dc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05dc
.L_lambda_simple_env_end_05dc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05dc:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_05dc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05dc
.L_lambda_simple_params_end_05dc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05dc
	jmp .L_lambda_simple_end_05dc
.L_lambda_simple_code_05dc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05dc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05dc:
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
.L_lambda_simple_env_loop_05dd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_05dd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05dd
.L_lambda_simple_env_end_05dd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05dd:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05dd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05dd
.L_lambda_simple_params_end_05dd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05dd
	jmp .L_lambda_simple_end_05dd
.L_lambda_simple_code_05dd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05dd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05dd:
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
.L_lambda_simple_env_loop_05de:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_05de
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05de
.L_lambda_simple_env_end_05de:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05de:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_05de
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05de
.L_lambda_simple_params_end_05de:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05de
	jmp .L_lambda_simple_end_05de
.L_lambda_simple_code_05de:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_05de
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05de:
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
	je .L_if_else_0455
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
.L_tc_recycle_frame_loop_07b2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07b2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07b2
.L_tc_recycle_frame_done_07b2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0455

	.L_if_else_0455:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec

	.L_if_end_0455:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05de:	; new closure is in rax

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
.L_tc_recycle_frame_loop_07b3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07b3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07b3
.L_tc_recycle_frame_done_07b3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05dd:	; new closure is in rax
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
.L_tc_recycle_frame_loop_07b4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07b4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07b4
.L_tc_recycle_frame_done_07b4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_05dc:	; new closure is in rax
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
.L_tc_recycle_frame_loop_07b5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07b5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07b5
.L_tc_recycle_frame_done_07b5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_05db:	; new closure is in rax
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
.L_lambda_simple_env_loop_05df:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05df
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05df
.L_lambda_simple_env_end_05df:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05df:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05df
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05df
.L_lambda_simple_params_end_05df:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05df
	jmp .L_lambda_simple_end_05df
.L_lambda_simple_code_05df:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_05df
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05df:
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
	je .L_if_else_0456
	mov rax, L_constants + 3469

	jmp .L_if_end_0456

	.L_if_else_0456:
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
	je .L_if_else_0457
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
.L_tc_recycle_frame_loop_07b6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07b6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07b6
.L_tc_recycle_frame_done_07b6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	jmp .L_if_end_0457

	.L_if_else_0457:
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
	je .L_if_else_0458
	mov rax, L_constants + 3469

	jmp .L_if_end_0458

	.L_if_else_0458:
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
.L_tc_recycle_frame_loop_07b7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07b7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07b7
.L_tc_recycle_frame_done_07b7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)

	.L_if_end_0458:

	.L_if_end_0457:

	.L_if_end_0456:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_05df:	; new closure is in rax
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
.L_lambda_simple_env_loop_05e0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_05e0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_05e0
.L_lambda_simple_env_end_05e0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_05e0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_05e0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_05e0
.L_lambda_simple_params_end_05e0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_05e0
	jmp .L_lambda_simple_end_05e0
.L_lambda_simple_code_05e0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_05e0
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_05e0:
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
.L_tc_recycle_frame_loop_07b8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_07b8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_07b8
.L_tc_recycle_frame_done_07b8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_05e0:	; new closure is in rax
	mov qword [free_var_176], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 3515
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

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