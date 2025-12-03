import os

def create_files():
    # Define the specific values for each group
    # %1%: 0 or 1
    group_1 = [0, 1]
    
    # %2%: Specific list of numbers
    group_2 = [1, 2, 3, 4, 5, 10, 15, 20, 30, 50]
    
    # %3%: 1 to 10 (range(1, 11) goes up to but does not include 11)
    group_3 = range(1, 11)

    # Create a directory to keep things organized
    output_dir = "generated_npc_files"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Created directory: {output_dir}")

    count = 0

    # Loop through all combinations
    for val1 in group_1:
        for val2 in group_2:
            for val3 in group_3:
                # Construct the filename: %1%_npc_%2%_experiment_%3%.txt
                filename = f"{val1}_npc_{val2}_experiment_{val3}.txt"
                filepath = os.path.join(output_dir, filename)
                
                # Create the empty file
                # 'w' mode opens for writing (creating if not exists)
                # 'pass' does nothing, effectively leaving it empty
                with open(filepath, 'w') as f:
                    pass
                
                count += 1

    print(f"Success! Created {count} empty files in the '{output_dir}' folder.")

if __name__ == "__main__":
    create_files()