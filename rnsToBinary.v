`define N 280 // N = sum of moduli: 8*7*5 = 280
`define BITS8 [8:6] // Bit location of 8 modulus
`define BITS7 [5:3] // Bit location of 7 modulus
`define BITS5 [2:0] // Bit location of 5 modulus
`define N_BITS 9 // Number of bits in our RNS number
`define INT [31:0] // Using a 32 bit integer system

// Determine RNS bits
// `define BITS 'b0011011011 // Should result in 3
// `define BITS 'b0011100011 // Should result in 123
`define BITS 'b110001011 // Should result in 78

// Computes the partial result for each modulus residue
module residue(residue, done, b, modulus, clock, reset);
  // Input/output logic
  output reg `INT residue;
  output reg done; // Signals that the operation is complete
  input wire `INT b; // RNS bits
  input wire `INT modulus; // Which moduli to use for the RNS segment
  input clock;
  input reset; // Pulsed on when a new number is to be converted

  // Internal logic
  reg xiDone; // Signals when the modular inverse computation is done
  integer inverse; // Iterates through possible numbers for the modular inverse
  integer Ni; // Ni = N / modulus
  integer a; // Number used to find inverse calculation: a = Ni % modulus

  // Handle computation logic on clock tick
  always @(posedge clock) begin
    if (reset) begin
      // Handle reset, turn off done signals and recompute variables
      done <= 0;
      xiDone <= 0;
      inverse = 1;
      Ni = `N/modulus;
      a = (`N/modulus) % modulus;
    end else begin
      // Continue calculating the xi modular inverse if it isn't complete yet
      if (xiDone == 0 && done == 0) begin
        if ((a*inverse) % modulus == 1) begin
          // Inverse has been found and stored in the inverse reg, set xiDone
          xiDone <= 1;
        end else if (inverse > 8) begin
          // No inverse found, set residue to 0
          residue <= 0;
          done <= 1;
        end else begin
          // Increment inverse for further checking
          inverse <= inverse + 1;
        end
      end

      // Inverse has been computed: now the final result can be computed
      if (xiDone == 1 && done == 0) begin
        residue <= inverse * b * Ni;
        done <= 1;
      end
    end
  end
endmodule

// Converts a binary number to
module rnsToBinary(result, done, bits, clock, reset);
  output reg `INT result; // Integer result of RNS to decimal binary
  output reg done; // Signals that the computation is complete
  input wire [`N_BITS-1:0] bits;
  input clock;
  input reset; // Reset rising edge to clear the module for new number

  // Internal logic
  integer b8, b7, b5; // Residue bits
  integer mod8 = 8;
  integer mod7 = 7;
  integer mod5 = 5;
  wire `INT result8, result7, result5;
  wire done8, done7, done5;

  residue residue8(result8, done8, b8, mod8, clock, reset);
  residue residue7(result7, done7, b7, mod7, clock, reset);
  residue residue5(result5, done5, b5, mod5, clock, reset);

  // Wait for partial results of mod 8, 7, and 5 to be complete, then calculate
  // the final result as sum(residue results) % N
  always @(posedge clock) begin
    if (reset) begin
      // Handle reset signal
      b8 = bits`BITS8;
      b7 = bits`BITS7;
      b5 = bits`BITS5;
      done <= 0;
    end else begin
      if (done8 && done7 && done5 && reset == 0) begin
        result <= (result8 + result7 + result5) % `N;
        done <= 1;
      end
    end
  end
endmodule

// // Example of the rnsToBinary module working
// module tryit;
//   // Initializations
//   wire [`N_BITS-1:0] bits = `BITS; // Bits in RNS representation
//   reg clock;
//   reg reset;
//   reg printed = 0; // Used so that the result is only printed once
//   wire `INT result;
//   wire done; // Done signal
//
//   rnsToBinary myRns(result, done, bits, clock, reset);
//
//   initial begin
//     clock = 0;
//     reset = 1;
//     #5 reset = 0;
//
//     // Iterate through 50 clock cycles, print result
//     repeat (100) begin
//       #1 clock = ~clock;
//       if (done && printed==0) begin
//         $display("Result:", result);
//         printed <= 1;
//       end
//     end
//   end
// endmodule

// Tests all valid RNS combinations for a (8,7,5) system
module testbench;
  // Initializations
  reg [`N_BITS-1:0] bits = 0; // Bits in RNS representation
  reg clock;
  reg reset;
  reg printed = 0; // Used so that the result is only printed once
  reg[31:0] bin = 0;
  integer i = 0;
  wire `INT result;
  wire done; // Done signal

  rnsToBinary myRns(result, done, bits, clock, reset);

  initial begin
    clock = 0;
    reset <= 1;
    printed <= 0;
    // Cycle through all 280 RNS possibilities and check for errors
    repeat (280) begin
      i <= 0;
      printed <= 0;
      // Iterate through 250 clock cycles, print result
      repeat (500) begin
        #1 clock = ~clock;
        if(i == 10) begin
          // Load new bits while in reset
          bits[8:6] <= bin % 8;
          bits[5:3] <= bin % 7;
          bits[2:0] <= bin % 5;
        end
        if(i == 20) begin
          // Turn off reset to begin new conversion
          reset <= 0;
        end
        if (done && printed==0) begin
          $display("Expected:", bin);
          $display("Result:  ", result);
          if (result != bin) begin
            $display("Error converting decimal digit:", bin);
          end else begin
            $display("Successful conversion\n");
          end
          printed <= 1;
        end
        if (i == 400) begin
          // Increment to next number to check
          bin <= bin + 1;
          reset <= 1; // Pull reset high while changing input
        end
        i <= i + 1;
      end
    end
  end
endmodule
