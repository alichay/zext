import "zext:fmt.odin"

main :: proc() {
	fmt.println("This should produce:\n1 2 3 1 4 {} 12 3 1.100 1.200 {13} test");
	fmt.printp("{} {} {} {1} {} {{} {s1}{} {} {11} {12} {{13} test\n", 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1.1, 1.2);

}