# Methods for RNS to Binary Conversion: Classic Logic and Neural Networks
The Residue Number System (RNS) is a novel method used to represent integer numbers: an alternative to binary. RNS works by selecting a list of relatively prime numbers such as [8,7,5] or [11,7,5,3]. To convert an integer to RNS, you take the integer and apply the modulus operation with each of the relatively prime numbers acting as the moduli. For example, to convert the integer 78 using the moduli [8,7,5]:  
``` 
78 % 8 = 6 = 0b110
78 % 7 = 1 = 0b001
78 % 5 = 3 = 0b011
```
The final RNS representation is the modulus bits concatenated together: `0b110001011`. 

RNS is most useful for performing arithmetic on very large numbers. When adding, subtracting, or multiplying two RNS numbers, you just add/subtract/multiply each residue together to form the result. For example, if you are performing addition of two numbers using moduli [8,7,5], you would add the two (mod 8) residues, two (mod 7) residues, and the two (mod 5) residues all independently. Ultimately, this allows for a lot of parallelization within the RNS arithmetic, something that classic binary integer representation cannot do.

This repository has both classic logic ciruit implementations (`rnsToBinary.v`) and attempted neural network methods (`rns_to_binary.ipynb`). Everything is recorded and summarized in a report (`Methods for RNS to Binary Conversion.pdf`).
