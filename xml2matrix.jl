using Debugger
using EzXML

pwd()
cd("/Users/BREN/Desktop/coursework/csus-stat196k-BigData/assignments/13-h-xml-to-matrix/")

f = "fsf.xml"
f = "file1.xml"

doc = EzXML.readxml(f)
root(doc)

org_desc = findall("//Desc", root(doc))
nodecontent(org_desc[1])
[nodecontent(i) for i in org_desc]

mission_desc = findall("//MissionDesc", root(doc))
[nodecontent(i) for i in mission_desc]
[nodecontent(i) for i in findall("//MissionDescription", root(doc))]

org_desc = findfirst("//Desc/text()", doc)
nodecontent(org_desc)
if isnothing(org_desc)
    org_desc = findfirst("//Description/text()", doc)
end


### 1:04:00 from Zoom on 3/15
### Save results as key:value pairs via either an array (keys:values) or a
### data frame (columns:rows

### 1:07:00 for extracting elements into array of strings for corpus creation)


function getcontent(xml_file)
    doc = EzXML.readxml(xml_file)
    org_desc = findfirst("//Desc/text()", doc)
    if isnothing(org_desc)
        org_desc = findfirst("//Description/text()", doc)
    end
end

map(getcontent, files)
    