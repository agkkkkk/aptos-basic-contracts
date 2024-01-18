module test::test {
    fun sum(num1: u64, num2: u64): u64 {
        num1 + num2
    }

    spec sum {
        ensures result == num1 + num2;
    }
}