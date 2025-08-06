import os

def collect_dart_files(root_dir):
    dart_files = []
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith(".dart"):
                dart_files.append(os.path.join(dirpath, filename))
    return dart_files

def generate_concatenated_output(dart_files, output_file):
    with open(output_file, "w", encoding="utf-8") as outfile:
        for file_path in dart_files:
            outfile.write(f"Full Path::{os.path.abspath(file_path)}\n")
            with open(file_path, "r", encoding="utf-8") as dart_file:
                for i, line in enumerate(dart_file, start=1):
                    clean_line = line.rstrip("\n")
                    outfile.write(f"{i}::{clean_line}\n")
            outfile.write("\n")  # Séparation entre fichiers

if __name__ == "__main__":
    import sys

    if len(sys.argv) < 3:
        print("Usage: python script.py <chemin_du_dossier> <fichier_de_sortie>")
    else:
        dossier_source = sys.argv[1]
        fichier_sortie = sys.argv[2]

        fichiers_dart = collect_dart_files(dossier_source)
        generate_concatenated_output(fichiers_dart, fichier_sortie)
        print(f"Fichier généré : {fichier_sortie}")


# Ex: python concat_dart_files.py ./mon_projet_dart output.txt