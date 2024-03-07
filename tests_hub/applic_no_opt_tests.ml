
let antp_no_opt_tests : cg_test list = [
  {test = "((lambda () 1))"; expected = "1"};
  {test = "((lambda (x) x) 1)"; expected = "1"};
  {test = "((lambda (x y) `(,y)) 1 2)"; expected = "(2)"};
  {test = "(define f (lambda (x y) y)) (f 1 2)"; expected = "2"};
  {test = "(let ((x 1) (y 2)) y x)"; expected = "1"};
  {test = "((lambda (x) (__bin-add-zz x 1)) 1)"; expected = "2"};
  {test = "
(define fact 
    (letrec ((f (lambda (n) 
                  (if (__bin-equal-zz 0 n) 
                      1
                      (__bin-mul-zz n (f (__bin-sub-zz n 1)))))))
            f))
(fact 5)"; expected = "120"};
]
