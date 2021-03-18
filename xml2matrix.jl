using Debugger
using EzXML
using TextAnalysis
using DataFrames

f = "file1.xml"
f = "file2.xml"

doc = EzXML.readxml(f)
root(doc)

org_desc = findall("//Desc", root(doc))
nodecontent(org_desc[1])
[nodecontent(i) for i in org_desc]

mission_desc = findall("//MissionDesc", root(doc))
[nodecontent(i) for i in mission_desc]
[nodecontent(i) for i in findall("//MissionDescription", root(doc))] # Empty!!

org_desc = findfirst("//Desc/text()", doc)
# nodecontent(org_desc)
if isnothing(org_desc)
    org_desc = findfirst("//Description/text()", doc)
end
# nodecontent(org_desc)


### 3/15 1:04:00
### Save results as key:value pairs via either an array (keys:values) or a
### data frame (columns:rows)

### 1:07:00 for extracting elements into array of strings for corpus creation)


function extract_text(xml_file)
    doc = EzXML.readxml(xml_file)
    org_desc = findfirst("//Desc/text()", doc)
    if isnothing(org_desc)
        org_desc = findfirst("//Description/text()", doc)
    end
    return org_desc
end

map(extract_text, file_list)
    
## PSEUDOCODE -------------------------
# Read in XML file names
file_list = readdir("./data")

for file in file_list
    doc = extract_text(file)
    StringDocument(doc)
    tokens(doc)
    prepare!(doc, strip_punctuation)
    remove_case!(doc)
    stem!(doc)
end

# Extract text
function extract_text(xml_file)
    doc = EzXML.readxml(xml_file)
    org_name = findfirst("//Name/text()", doc)
    org_size = readxml()
    org_doc = readxml()
end

# Process text

create_dtm()
update_corpus()
