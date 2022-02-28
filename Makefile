build:
	@echo "Building..."
	@flex tema.l
	@gcc -o exec lex.yy.c -lfl
	@echo "Done"

run:
	
	@echo "Runing Test1"
	@./exec < test1.txt > test1_out.txt
	@if cmp -s test1_out.txt test1_ref.txt; then \
        echo "Test1 passed";\
	else \
        echo "Test1 failed";\
    fi

	@echo "Runing Test2"
	@./exec < test2.txt > test2_out.txt
	@if cmp -s test2_out.txt test2_ref.txt; then \
        echo "Test2 passed";\
	else \
        echo "Test2 failed";\
    fi

	@echo "Runing Test3"
	@./exec < test3.txt > test3_out.txt
	@if cmp -s test3_out.txt test3_ref.txt; then \
        echo "Test3 passed";\
	else \
        echo "Test3 failed";\
    fi

	@echo "Runing Test4"
	@./exec < test4.txt > test4_out.txt
	@if cmp -s test4_out.txt test4_ref.txt; then \
        echo "Test4 passed";\
	else \
        echo "Test4 failed";\
    fi

	@echo "Done"
clean:
	@echo "Cleaning..."
	@rm -rf test1_out.txt test2_out.txt test3_out.txt test4_out.txt exec
	@echo "Done"
