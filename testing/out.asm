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
.L_lambda_simple_env_loop_0001:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0001
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0001
.L_lambda_simple_env_end_0001:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0001:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0001
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0001
.L_lambda_simple_params_end_0001:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0001
	jmp .L_lambda_simple_end_0001
.L_lambda_simple_code_0001:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0001
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0001:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0001:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0001
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0001
.L_tc_recycle_frame_done_0001:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0001:	; new closure is in rax
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
.L_lambda_simple_env_loop_0002:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0002
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0002
.L_lambda_simple_env_end_0002:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0002:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0002
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0002
.L_lambda_simple_params_end_0002:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0002
	jmp .L_lambda_simple_end_0002
.L_lambda_simple_code_0002:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0002
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0002:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0002:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0002
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0002
.L_tc_recycle_frame_done_0002:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0002:	; new closure is in rax
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
.L_lambda_simple_env_loop_0003:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0003
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0003
.L_lambda_simple_env_end_0003:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0003:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0003
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0003
.L_lambda_simple_params_end_0003:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0003
	jmp .L_lambda_simple_end_0003
.L_lambda_simple_code_0003:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0003
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0003:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0003:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0003
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0003
.L_tc_recycle_frame_done_0003:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0003:	; new closure is in rax
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
.L_lambda_simple_env_loop_0004:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0004
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0004
.L_lambda_simple_env_end_0004:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0004:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0004
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0004
.L_lambda_simple_params_end_0004:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0004
	jmp .L_lambda_simple_end_0004
.L_lambda_simple_code_0004:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0004
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0004:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0004:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0004
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0004
.L_tc_recycle_frame_done_0004:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0004:	; new closure is in rax
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
.L_lambda_simple_env_loop_0005:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0005
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0005
.L_lambda_simple_env_end_0005:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0005:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0005
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0005
.L_lambda_simple_params_end_0005:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0005
	jmp .L_lambda_simple_end_0005
.L_lambda_simple_code_0005:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0005
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0005:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0005:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0005
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0005
.L_tc_recycle_frame_done_0005:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0005:	; new closure is in rax
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
.L_lambda_simple_env_loop_0006:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0006
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0006
.L_lambda_simple_env_end_0006:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0006:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0006
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0006
.L_lambda_simple_params_end_0006:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0006
	jmp .L_lambda_simple_end_0006
.L_lambda_simple_code_0006:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0006
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0006:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0006:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0006
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0006
.L_tc_recycle_frame_done_0006:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0006:	; new closure is in rax
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
.L_lambda_simple_env_loop_0007:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0007
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0007
.L_lambda_simple_env_end_0007:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0007:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0007
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0007
.L_lambda_simple_params_end_0007:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0007
	jmp .L_lambda_simple_end_0007
.L_lambda_simple_code_0007:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0007
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0007:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0007:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0007
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0007
.L_tc_recycle_frame_done_0007:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0007:	; new closure is in rax
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
.L_lambda_simple_env_loop_0008:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0008
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0008
.L_lambda_simple_env_end_0008:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0008:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0008
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0008
.L_lambda_simple_params_end_0008:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0008
	jmp .L_lambda_simple_end_0008
.L_lambda_simple_code_0008:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0008
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0008:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0008:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0008
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0008
.L_tc_recycle_frame_done_0008:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0008:	; new closure is in rax
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
.L_lambda_simple_env_loop_0009:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0009
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0009
.L_lambda_simple_env_end_0009:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0009:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0009
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0009
.L_lambda_simple_params_end_0009:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0009
	jmp .L_lambda_simple_end_0009
.L_lambda_simple_code_0009:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0009
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0009:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0009:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0009
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0009
.L_tc_recycle_frame_done_0009:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0009:	; new closure is in rax
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
.L_lambda_simple_env_loop_000a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_000a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_000a
.L_lambda_simple_env_end_000a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_000a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_000a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_000a
.L_lambda_simple_params_end_000a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_000a
	jmp .L_lambda_simple_end_000a
.L_lambda_simple_code_000a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_000a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_000a:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_000a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_000a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_000a
.L_tc_recycle_frame_done_000a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_000a:	; new closure is in rax
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
.L_lambda_simple_env_loop_000b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_000b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_000b
.L_lambda_simple_env_end_000b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_000b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_000b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_000b
.L_lambda_simple_params_end_000b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_000b
	jmp .L_lambda_simple_end_000b
.L_lambda_simple_code_000b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_000b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_000b:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_000b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_000b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_000b
.L_tc_recycle_frame_done_000b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_000b:	; new closure is in rax
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
.L_lambda_simple_env_loop_000c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_000c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_000c
.L_lambda_simple_env_end_000c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_000c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_000c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_000c
.L_lambda_simple_params_end_000c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_000c
	jmp .L_lambda_simple_end_000c
.L_lambda_simple_code_000c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_000c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_000c:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_000c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_000c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_000c
.L_tc_recycle_frame_done_000c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_000c:	; new closure is in rax
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
.L_lambda_simple_env_loop_000d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_000d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_000d
.L_lambda_simple_env_end_000d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_000d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_000d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_000d
.L_lambda_simple_params_end_000d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_000d
	jmp .L_lambda_simple_end_000d
.L_lambda_simple_code_000d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_000d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_000d:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_000d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_000d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_000d
.L_tc_recycle_frame_done_000d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_000d:	; new closure is in rax
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
.L_lambda_simple_env_loop_000e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_000e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_000e
.L_lambda_simple_env_end_000e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_000e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_000e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_000e
.L_lambda_simple_params_end_000e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_000e
	jmp .L_lambda_simple_end_000e
.L_lambda_simple_code_000e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_000e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_000e:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_000e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_000e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_000e
.L_tc_recycle_frame_done_000e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_000e:	; new closure is in rax
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
.L_lambda_simple_env_loop_000f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_000f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_000f
.L_lambda_simple_env_end_000f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_000f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_000f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_000f
.L_lambda_simple_params_end_000f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_000f
	jmp .L_lambda_simple_end_000f
.L_lambda_simple_code_000f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_000f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_000f:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_000f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_000f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_000f
.L_tc_recycle_frame_done_000f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_000f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0010:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0010
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0010
.L_lambda_simple_env_end_0010:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0010:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0010
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0010
.L_lambda_simple_params_end_0010:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0010
	jmp .L_lambda_simple_end_0010
.L_lambda_simple_code_0010:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0010
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0010:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0010:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0010
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0010
.L_tc_recycle_frame_done_0010:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0010:	; new closure is in rax
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
.L_lambda_simple_env_loop_0011:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0011
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0011
.L_lambda_simple_env_end_0011:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0011:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0011
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0011
.L_lambda_simple_params_end_0011:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0011
	jmp .L_lambda_simple_end_0011
.L_lambda_simple_code_0011:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0011
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0011:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0011:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0011
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0011
.L_tc_recycle_frame_done_0011:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0011:	; new closure is in rax
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
.L_lambda_simple_env_loop_0012:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0012
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0012
.L_lambda_simple_env_end_0012:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0012:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0012
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0012
.L_lambda_simple_params_end_0012:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0012
	jmp .L_lambda_simple_end_0012
.L_lambda_simple_code_0012:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0012
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0012:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0012:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0012
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0012
.L_tc_recycle_frame_done_0012:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0012:	; new closure is in rax
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
.L_lambda_simple_env_loop_0013:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0013
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0013
.L_lambda_simple_env_end_0013:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0013:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0013
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0013
.L_lambda_simple_params_end_0013:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0013
	jmp .L_lambda_simple_end_0013
.L_lambda_simple_code_0013:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0013
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0013:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0013:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0013
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0013
.L_tc_recycle_frame_done_0013:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0013:	; new closure is in rax
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
.L_lambda_simple_env_loop_0014:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0014
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0014
.L_lambda_simple_env_end_0014:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0014:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0014
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0014
.L_lambda_simple_params_end_0014:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0014
	jmp .L_lambda_simple_end_0014
.L_lambda_simple_code_0014:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0014
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0014:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0014:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0014
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0014
.L_tc_recycle_frame_done_0014:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0014:	; new closure is in rax
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
.L_lambda_simple_env_loop_0015:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0015
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0015
.L_lambda_simple_env_end_0015:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0015:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0015
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0015
.L_lambda_simple_params_end_0015:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0015
	jmp .L_lambda_simple_end_0015
.L_lambda_simple_code_0015:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0015
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0015:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0015:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0015
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0015
.L_tc_recycle_frame_done_0015:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0015:	; new closure is in rax
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
.L_lambda_simple_env_loop_0016:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0016
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0016
.L_lambda_simple_env_end_0016:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0016:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0016
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0016
.L_lambda_simple_params_end_0016:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0016
	jmp .L_lambda_simple_end_0016
.L_lambda_simple_code_0016:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0016
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0016:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0016:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0016
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0016
.L_tc_recycle_frame_done_0016:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0016:	; new closure is in rax
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
.L_lambda_simple_env_loop_0017:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0017
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0017
.L_lambda_simple_env_end_0017:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0017:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0017
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0017
.L_lambda_simple_params_end_0017:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0017
	jmp .L_lambda_simple_end_0017
.L_lambda_simple_code_0017:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0017
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0017:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0017:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0017
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0017
.L_tc_recycle_frame_done_0017:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0017:	; new closure is in rax
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
.L_lambda_simple_env_loop_0018:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0018
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0018
.L_lambda_simple_env_end_0018:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0018:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0018
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0018
.L_lambda_simple_params_end_0018:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0018
	jmp .L_lambda_simple_end_0018
.L_lambda_simple_code_0018:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0018
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0018:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0018:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0018
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0018
.L_tc_recycle_frame_done_0018:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0018:	; new closure is in rax
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
.L_lambda_simple_env_loop_0019:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0019
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0019
.L_lambda_simple_env_end_0019:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0019:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0019
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0019
.L_lambda_simple_params_end_0019:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0019
	jmp .L_lambda_simple_end_0019
.L_lambda_simple_code_0019:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0019
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0019:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0019:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0019
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0019
.L_tc_recycle_frame_done_0019:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0019:	; new closure is in rax
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
.L_lambda_simple_env_loop_001a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_001a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_001a
.L_lambda_simple_env_end_001a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_001a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_001a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_001a
.L_lambda_simple_params_end_001a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_001a
	jmp .L_lambda_simple_end_001a
.L_lambda_simple_code_001a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_001a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_001a:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_001a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_001a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_001a
.L_tc_recycle_frame_done_001a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_001a:	; new closure is in rax
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
.L_lambda_simple_env_loop_001b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_001b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_001b
.L_lambda_simple_env_end_001b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_001b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_001b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_001b
.L_lambda_simple_params_end_001b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_001b
	jmp .L_lambda_simple_end_001b
.L_lambda_simple_code_001b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_001b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_001b:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_001b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_001b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_001b
.L_tc_recycle_frame_done_001b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_001b:	; new closure is in rax
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
.L_lambda_simple_env_loop_001c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_001c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_001c
.L_lambda_simple_env_end_001c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_001c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_001c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_001c
.L_lambda_simple_params_end_001c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_001c
	jmp .L_lambda_simple_end_001c
.L_lambda_simple_code_001c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_001c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_001c:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_001c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_001c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_001c
.L_tc_recycle_frame_done_001c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_001c:	; new closure is in rax
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
.L_lambda_simple_env_loop_001d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_001d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_001d
.L_lambda_simple_env_end_001d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_001d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_001d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_001d
.L_lambda_simple_params_end_001d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_001d
	jmp .L_lambda_simple_end_001d
.L_lambda_simple_code_001d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_001d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_001d:
	enter 0, 0
hi7	cmp rax, sob_boolean_false
	jne .L_or_end_0001
hi7
	cmp rax, sob_false
	je .L_if_else_0001
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_001d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_001d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_001d
.L_tc_recycle_frame_done_001d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0001
	.L_if_else_0001:
	mov rax, L_constants + 2
	.L_if_end_0001:
.L_or_end_0001:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_001d:	; new closure is in rax
	mov qword [free_var_102], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi6	mov qword [free_var_103], rax
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
.L_lambda_simple_env_loop_001e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_001e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_001e
.L_lambda_simple_env_end_001e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_001e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_001e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_001e
.L_lambda_simple_params_end_001e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_001e
	jmp .L_lambda_simple_end_001e
.L_lambda_simple_code_001e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_001e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_001e:
	enter 0, 0
	mov rax, PARAM(0)	; param x

	cmp rax, sob_false
	je .L_if_else_0002
	mov rax, L_constants + 2
	jmp .L_if_end_0002
	.L_if_else_0002:
	mov rax, L_constants + 3
	.L_if_end_0002:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_001e:	; new closure is in rax
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
.L_lambda_simple_env_loop_001f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_001f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_001f
.L_lambda_simple_env_end_001f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_001f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_001f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_001f
.L_lambda_simple_params_end_001f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_001f
	jmp .L_lambda_simple_end_001f
.L_lambda_simple_code_001f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_001f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_001f:
	enter 0, 0
hi7	cmp rax, sob_boolean_false
	jne .L_or_end_0002
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
.L_tc_recycle_frame_loop_001e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_001e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_001e
.L_tc_recycle_frame_done_001e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_0002:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_001f:	; new closure is in rax
	mov qword [free_var_105], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_106], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_107], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi6	mov qword [free_var_108], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi6	mov qword [free_var_110], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_109], rax
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
.L_lambda_simple_env_loop_0020:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0020
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0020
.L_lambda_simple_env_end_0020:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0020:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0020
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0020
.L_lambda_simple_params_end_0020:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0020
	jmp .L_lambda_simple_end_0020
.L_lambda_simple_code_0020:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0020
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0020:
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
.L_lambda_simple_env_loop_0021:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0021
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0021
.L_lambda_simple_env_end_0021:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0021:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0021
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0021
.L_lambda_simple_params_end_0021:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0021
	jmp .L_lambda_simple_end_0021
.L_lambda_simple_code_0021:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0021
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0021:
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
.L_tc_recycle_frame_loop_001f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_001f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_001f
.L_tc_recycle_frame_done_001f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0021:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0020:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0020
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0020
.L_tc_recycle_frame_done_0020:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0020:	; new closure is in rax
	mov qword [free_var_111], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_113], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_112], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_114], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_115], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_117], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_119], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_120], rax
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
.L_lambda_simple_env_loop_0022:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0022
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0022
.L_lambda_simple_env_end_0022:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0022:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0022
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0022
.L_lambda_simple_params_end_0022:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0022
	jmp .L_lambda_simple_end_0022
.L_lambda_simple_code_0022:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0022
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0022:
	enter 0, 0
hi7
	cmp rax, sob_false
	je .L_if_else_0003
	mov rax, L_constants + 2158
	jmp .L_if_end_0003
	.L_if_else_0003:
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0021:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0021
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0021
.L_tc_recycle_frame_done_0021:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	.L_if_end_0003:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0022:	; new closure is in rax
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

hi7
	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_127], rax
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

hi7
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

hi7
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

hi7
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

hi7
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

hi7
	mov rdi, rax
	call print_sexpr_if_not_void

hi7
	mov rdi, rax
	call print_sexpr_if_not_void

hi7
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
.L_lambda_simple_env_loop_0023:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0023
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0023
.L_lambda_simple_env_end_0023:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0023:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0023
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0023
.L_lambda_simple_params_end_0023:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0023
	jmp .L_lambda_simple_end_0023
.L_lambda_simple_code_0023:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0023
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0023:
	enter 0, 0
hi7
	cmp rax, sob_false
	je .L_if_else_0004
	mov rax, L_constants + 2023
	jmp .L_if_end_0004
	.L_if_else_0004:
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0022:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0022
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0022
.L_tc_recycle_frame_done_0022:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	.L_if_end_0004:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0023:	; new closure is in rax
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
.L_lambda_simple_env_loop_0024:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0024
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0024
.L_lambda_simple_env_end_0024:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0024:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0024
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0024
.L_lambda_simple_params_end_0024:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0024
	jmp .L_lambda_simple_end_0024
.L_lambda_simple_code_0024:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0024
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0024:
	enter 0, 0
hi7	cmp rax, sob_boolean_false
	jne .L_or_end_0003
hi7
	cmp rax, sob_false
	je .L_if_else_0005
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0023:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0023
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0023
.L_tc_recycle_frame_done_0023:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0005
	.L_if_else_0005:
	mov rax, L_constants + 2
	.L_if_end_0005:
.L_or_end_0003:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0024:	; new closure is in rax
	mov qword [free_var_102], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_57], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_58], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_155], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_142], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi6	mov qword [free_var_156], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_143], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_157], rax
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
.L_lambda_simple_env_loop_0025:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0025
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0025
.L_lambda_simple_env_end_0025:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0025:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0025
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0025
.L_lambda_simple_params_end_0025:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0025
	jmp .L_lambda_simple_end_0025
.L_lambda_simple_code_0025:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0025
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0025:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param n
	push rax
hi7	push rax
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
.L_tc_recycle_frame_loop_0024:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0024
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0024
.L_tc_recycle_frame_done_0024:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0025:	; new closure is in rax
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
.L_lambda_simple_env_loop_0026:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0026
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0026
.L_lambda_simple_env_end_0026:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0026:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0026
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0026
.L_lambda_simple_params_end_0026:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0026
	jmp .L_lambda_simple_end_0026
.L_lambda_simple_code_0026:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0026
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0026:
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
.L_tc_recycle_frame_loop_0025:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0025
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0025
.L_tc_recycle_frame_done_0025:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0026:	; new closure is in rax
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
.L_lambda_simple_env_loop_0027:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0027
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0027
.L_lambda_simple_env_end_0027:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0027:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0027
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0027
.L_lambda_simple_params_end_0027:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0027
	jmp .L_lambda_simple_end_0027
.L_lambda_simple_code_0027:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0027
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0027:
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
.L_tc_recycle_frame_loop_0026:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0026
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0026
.L_tc_recycle_frame_done_0026:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0027:	; new closure is in rax
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
.L_lambda_simple_env_loop_0028:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0028
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0028
.L_lambda_simple_env_end_0028:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0028:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0028
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0028
.L_lambda_simple_params_end_0028:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0028
	jmp .L_lambda_simple_end_0028
.L_lambda_simple_code_0028:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0028
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0028:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0027:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0027
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0027
.L_tc_recycle_frame_done_0027:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0028:	; new closure is in rax
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
.L_lambda_simple_env_loop_0029:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0029
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0029
.L_lambda_simple_env_end_0029:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0029:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0029
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0029
.L_lambda_simple_params_end_0029:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0029
	jmp .L_lambda_simple_end_0029
.L_lambda_simple_code_0029:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0029
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0029:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0028:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0028
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0028
.L_tc_recycle_frame_done_0028:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0029:	; new closure is in rax
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
.L_lambda_simple_env_loop_002a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_002a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_002a
.L_lambda_simple_env_end_002a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_002a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_002a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_002a
.L_lambda_simple_params_end_002a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_002a
	jmp .L_lambda_simple_end_002a
.L_lambda_simple_code_002a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_002a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_002a:
	enter 0, 0
hi7
	cmp rax, sob_false
	je .L_if_else_0006
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
.L_tc_recycle_frame_loop_0029:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0029
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0029
.L_tc_recycle_frame_done_0029:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0006
	.L_if_else_0006:
	mov rax, PARAM(0)	; param x
	.L_if_end_0006:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_002a:	; new closure is in rax
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
.L_lambda_simple_env_loop_002b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_002b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_002b
.L_lambda_simple_env_end_002b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_002b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_002b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_002b
.L_lambda_simple_params_end_002b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_002b
	jmp .L_lambda_simple_end_002b
.L_lambda_simple_code_002b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_002b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_002b:
	enter 0, 0
hi7
	cmp rax, sob_false
	je .L_if_else_0008
hi7	jmp .L_if_end_0008
	.L_if_else_0008:
	mov rax, L_constants + 2
	.L_if_end_0008:

	cmp rax, sob_false
	je .L_if_else_0007
hi7
	cmp rax, sob_false
	je .L_if_else_0009
	; preparing a tail-call
hi7	push rax
hi7	push rax
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
.L_tc_recycle_frame_loop_002a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_002a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_002a
.L_tc_recycle_frame_done_002a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0009
	.L_if_else_0009:
	mov rax, L_constants + 2
	.L_if_end_0009:
	jmp .L_if_end_0007
	.L_if_else_0007:
hi7
	cmp rax, sob_false
	je .L_if_else_000b
hi7
	cmp rax, sob_false
	je .L_if_else_000c
hi7	jmp .L_if_end_000c
	.L_if_else_000c:
	mov rax, L_constants + 2
	.L_if_end_000c:
	jmp .L_if_end_000b
	.L_if_else_000b:
	mov rax, L_constants + 2
	.L_if_end_000b:

	cmp rax, sob_false
	je .L_if_else_000a
	; preparing a tail-call
hi7	push rax
hi7	push rax
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
.L_tc_recycle_frame_loop_002b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_002b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_002b
.L_tc_recycle_frame_done_002b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_000a
	.L_if_else_000a:
hi7
	cmp rax, sob_false
	je .L_if_else_000e
hi7
	cmp rax, sob_false
	je .L_if_else_000f
hi7	jmp .L_if_end_000f
	.L_if_else_000f:
	mov rax, L_constants + 2
	.L_if_end_000f:
	jmp .L_if_end_000e
	.L_if_else_000e:
	mov rax, L_constants + 2
	.L_if_end_000e:

	cmp rax, sob_false
	je .L_if_else_000d
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
.L_tc_recycle_frame_loop_002c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_002c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_002c
.L_tc_recycle_frame_done_002c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_000d
	.L_if_else_000d:
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
.L_tc_recycle_frame_loop_002d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_002d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_002d
.L_tc_recycle_frame_done_002d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	.L_if_end_000d:
	.L_if_end_000a:
	.L_if_end_0007:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_002b:	; new closure is in rax
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
.L_lambda_simple_env_loop_002c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_002c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_002c
.L_lambda_simple_env_end_002c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_002c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_002c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_002c
.L_lambda_simple_params_end_002c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_002c
	jmp .L_lambda_simple_end_002c
.L_lambda_simple_code_002c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_002c
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_002c:
	enter 0, 0
hi7
	cmp rax, sob_false
	je .L_if_else_0010
	mov rax, L_constants + 2
	jmp .L_if_end_0010
	.L_if_else_0010:
hi7
	cmp rax, sob_false
	je .L_if_else_0011
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
.L_tc_recycle_frame_loop_002e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_002e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_002e
.L_tc_recycle_frame_done_002e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0011
	.L_if_else_0011:
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_002f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_002f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_002f
.L_tc_recycle_frame_done_002f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	.L_if_end_0011:
	.L_if_end_0010:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_002c:	; new closure is in rax
	mov qword [free_var_165], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_166], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_167], rax
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
.L_lambda_simple_env_loop_002d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_002d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_002d
.L_lambda_simple_env_end_002d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_002d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_002d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_002d
.L_lambda_simple_params_end_002d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_002d
	jmp .L_lambda_simple_end_002d
.L_lambda_simple_code_002d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_002d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_002d:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0030:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0030
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0030
.L_tc_recycle_frame_done_0030:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_002d:	; new closure is in rax
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
.L_lambda_simple_env_loop_002e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_002e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_002e
.L_lambda_simple_env_end_002e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_002e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_002e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_002e
.L_lambda_simple_params_end_002e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_002e
	jmp .L_lambda_simple_end_002e
.L_lambda_simple_code_002e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_002e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_002e:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_0031:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0031
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0031
.L_tc_recycle_frame_done_0031:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_002e:	; new closure is in rax
	mov qword [free_var_169], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_170], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

hi7	mov qword [free_var_171], rax
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
.L_lambda_simple_env_loop_002f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_002f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_002f
.L_lambda_simple_env_end_002f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_002f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_002f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_002f
.L_lambda_simple_params_end_002f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_002f
	jmp .L_lambda_simple_end_002f
.L_lambda_simple_code_002f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_002f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_002f:
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
.L_lambda_simple_env_loop_0030:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0030
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0030
.L_lambda_simple_env_end_0030:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0030:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0030
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0030
.L_lambda_simple_params_end_0030:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0030
	jmp .L_lambda_simple_end_0030
.L_lambda_simple_code_0030:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0030
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0030:
	enter 0, 0
hi2
hi5
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
.L_tc_recycle_frame_loop_0032:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0032
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0032
.L_tc_recycle_frame_done_0032:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0030:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0033:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0033
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0033
.L_tc_recycle_frame_done_0033:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_002f:	; new closure is in rax
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
.L_lambda_simple_env_loop_0031:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0031
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0031
.L_lambda_simple_env_end_0031:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0031:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0031
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0031
.L_lambda_simple_params_end_0031:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0031
	jmp .L_lambda_simple_end_0031
.L_lambda_simple_code_0031:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0031
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0031:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_lambda_simple_env_loop_0032:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0032
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0032
.L_lambda_simple_env_end_0032:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0032:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0032
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0032
.L_lambda_simple_params_end_0032:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0032
	jmp .L_lambda_simple_end_0032
.L_lambda_simple_code_0032:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0032
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0032:
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
.L_lambda_simple_env_loop_0033:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0033
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0033
.L_lambda_simple_env_end_0033:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0033:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0033
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0033
.L_lambda_simple_params_end_0033:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0033
	jmp .L_lambda_simple_end_0033
.L_lambda_simple_code_0033:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0033
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0033:
	enter 0, 0
hi2
hi5
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
.L_tc_recycle_frame_loop_0034:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0034
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0034
.L_tc_recycle_frame_done_0034:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0033:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0035:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0035
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0035
.L_tc_recycle_frame_done_0035:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0032:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0036:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0036
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0036
.L_tc_recycle_frame_done_0036:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0031:	; new closure is in rax
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
.L_lambda_simple_env_loop_0034:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0034
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0034
.L_lambda_simple_env_end_0034:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0034:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0034
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0034
.L_lambda_simple_params_end_0034:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0034
	jmp .L_lambda_simple_end_0034
.L_lambda_simple_code_0034:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0034
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0034:
	enter 0, 0
	; preparing a tail-call
hi7	push rax
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
.L_lambda_simple_env_loop_0035:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_0035
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0035
.L_lambda_simple_env_end_0035:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0035:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_0035
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0035
.L_lambda_simple_params_end_0035:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0035
	jmp .L_lambda_simple_end_0035
.L_lambda_simple_code_0035:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0035
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0035:
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
.L_lambda_simple_env_loop_0036:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_0036
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0036
.L_lambda_simple_env_end_0036:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0036:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_0036
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0036
.L_lambda_simple_params_end_0036:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0036
	jmp .L_lambda_simple_end_0036
.L_lambda_simple_code_0036:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0036
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0036:
	enter 0, 0
hi2
hi5
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
.L_tc_recycle_frame_loop_0037:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0037
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0037
.L_tc_recycle_frame_done_0037:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0036:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0038:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0038
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0038
.L_tc_recycle_frame_done_0038:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0035:	; new closure is in rax
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
.L_tc_recycle_frame_loop_0039:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_0039
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_0039
.L_tc_recycle_frame_done_0039:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0034:	; new closure is in rax
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
.L_lambda_simple_env_loop_0037:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0037
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0037
.L_lambda_simple_env_end_0037:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0037:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0037
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0037
.L_lambda_simple_params_end_0037:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0037
	jmp .L_lambda_simple_end_0037
.L_lambda_simple_code_0037:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0037
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0037:
	enter 0, 0
hi7
	cmp rax, sob_false
	je .L_if_else_0012
	mov rax, L_constants + 3469
	jmp .L_if_end_0012
	.L_if_else_0012:
hi7
	cmp rax, sob_false
	je .L_if_else_0013
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_003a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_003a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_003a
.L_tc_recycle_frame_done_003a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0013
	.L_if_else_0013:
hi7
	cmp rax, sob_false
	je .L_if_else_0014
	mov rax, L_constants + 3469
	jmp .L_if_end_0014
	.L_if_else_0014:
	; preparing a tail-call
hi7	push rax
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
.L_tc_recycle_frame_loop_003b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_003b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_003b
.L_tc_recycle_frame_done_003b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	.L_if_end_0014:
	.L_if_end_0013:
	.L_if_end_0012:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0037:	; new closure is in rax
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
.L_lambda_simple_env_loop_0038:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_0038
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_0038
.L_lambda_simple_env_end_0038:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_0038:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_0038
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_0038
.L_lambda_simple_params_end_0038:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_0038
	jmp .L_lambda_simple_end_0038
.L_lambda_simple_code_0038:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0038
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0038:
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
.L_tc_recycle_frame_loop_003c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_003c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_003c
.L_tc_recycle_frame_done_003c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0038:	; new closure is in rax
	mov qword [free_var_176], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 3

	cmp rax, sob_false
	je .L_if_else_0015
	mov rax, L_constants + 3
	jmp .L_if_end_0015
	.L_if_else_0015:
	mov rax, L_constants + 3
	.L_if_end_0015:

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
	call fwrite
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
        call fwrite
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
