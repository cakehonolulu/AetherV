# Create a simple prog.hex file for RV32I initialization
hex_lines = [
    "00100093",  # ADDI x1, x0, 1
    "00200113",  # ADDI x2, x0, 2
    "002081B3",  # ADD  x3, x1, x2
    "0000006F"   # JAL  x0, 0   (infinite loop)
]

file_path = 'prog.hex'
with open(file_path, 'w') as f:
    for line in hex_lines:
        f.write(line + '\n')

# Display the contents for confirmation
with open(file_path) as f:
    contents = f.read()

print("Created prog.hex with the following contents:\n")
print(contents)
