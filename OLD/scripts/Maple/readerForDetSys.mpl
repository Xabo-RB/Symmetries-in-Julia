filename := "C:/Users/Even/Documents/GitHub/Symmetries-in-Julia/scripts/coefficients.txt";
if not FileTools:-Exists(filename) then
    ERROR("The file does not exist.");
end if;

try
    fileLines := FileTools[Text][ReadFile](filename, 'list');
catch:
    ERROR("Error reading the file.");
end try

lineas := StringTools:-Split(fileLines, "\n");
exprsMaple := [seq(parse(linea), linea in lineas)];