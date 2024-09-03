#include <stdio.h>

int sum(int *array, int length) {
    int sum = 0;

__asm__ __volatile__ (
        "xor %%eax, %%eax;"                 // Clear eax (set to 0, this will hold the sum)
        "xor %%ecx, %%ecx;"                 // Clear ecx (used as index counter)
        "sum_loop:"
        "add (%%rbx, %%rcx, 4), %%eax;"     // Add each array element to eax
        "inc %%ecx;"                        // Increment counter
        "cmp %%ecx, %%edx;"                 // Compare counter with length
        "jg sum_loop;"                      // If ecx < length, jump back to label sum_loop
        "mov %%eax, %0;"                    // Move the final sum into the sum variable
        : "=r" (sum)                        // Output: sum is stored in sum variable
        : "b" (array), "d" (length)         // Input: array in rbx, length in rdx
        : "%eax", "%ecx"                    // Clobbered registers
    );

    return sum;
}

int max(int *array, int length) {
    int max_val = 0;

    __asm__ __volatile__ (
        "mov (%1), %%eax;"          // Load the first element into EAX
        "mov %%eax, %0;"            // Initialize max_val with the first element
        "movl %2, %%ecx;"           // Move length into ECX for the loop counter
        "arr_loop:"
        "add $4, %1;"               // Move to the next element (increment pointer by 4 bytes)
        "dec %%ecx;"                // Decrement length (ECX)
        "cmp $0, %%ecx;"
        "je done;"                  // Jump to done if length is zero
        "mov (%1), %%eax;"          // Load the current element into EAX
        "cmp %%eax, %0;"            // Compare current element with max_val
        "jle arr_loop;"             // If max_val >= current element, continue
        "mov %%eax, %0;"            // Update max_val if current element is greater
        "jmp arr_loop;"             // Jump back to process the next element
        "done:"
        : "=r" (max_val), "+r" (array), "+r" (length)// Output: max_val will hold the maximum value
        :  // Inputs
        : "%eax", "%ecx"            // Clobbered registers
    );

    return max_val;
}

int dot_product(int *vec_a, int *vec_b, int length) {
    int result = 0;

    __asm__ __volatile__ (
        "movq $0, %%rax;"            // Initialize result (RAX) to 0
        "movl %3, %%ecx;"            // Move length into ECX (loop counter)
        "test %%ecx, %%ecx;"         // Check if length is zero
        "jz done_dot;"                   // If length is zero, jump to done
        "dot_loop:"
        "movl (%1), %%r8d;"          // Load vec1[i] into R8D (32-bit register)
        "imull (%2), %%r8d;"         // Multiply vec1[i] * vec2[i]
        "addl %%r8d, %%eax;"         // Add to result (EAX)
        "addq $4, %1;"               // Move to the next element in vec1
        "addq $4, %2;"               // Move to the next element in vec2
        "loop dot_loop;"             // Decrement ECX and loop if not zero
        "done_dot:"
        : "=a" (result), "+r" (vec_a), "+r" (vec_b), "+r" (length) // Output: result will be in EAX
        :  // Inputs
        : "%rcx", "%r8"              // Clobbered registers
    );
    return result;
}

int main() {
    int array[] = {1, 2, -3, 4, 5};
    int length = sizeof(array) / sizeof(array[0]);

    printf("Sum: %d\n", sum(array, length));
    printf("Max: %d\n", max(array, length));

    // Dot product
    int vec_a[] = {1, 2, 3};
    int vec_b[] = {4, 5, 6};
    int vec_length = sizeof(vec_a) / sizeof(vec_a[0]);

    int dot_result = dot_product(vec_a, vec_b, vec_length);
    printf("Dot Product: %d\n", dot_result);

    return 0;
}