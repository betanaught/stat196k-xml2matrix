using Debugger
using EzXML
using TextAnalysis
using DataFrames

function extract_name(xml_file)
    xml_string = EzXML.readxml(xml_file)
    org_name = nodecontent(findfirst("//Filer
                                      //BusinessName
                                      //BusinessNameLine1Txt/text()",
                                      xml_string))
    return org_name
end

function extract_size(xml_file)
    xml_string = EzXML.readxml(xml_file)
    org_size = nodecontent(findfirst("//TotalEmployeeCnt/text()", xml_string))
    return org_size
end

function extract_desc(xml_file)
    processed_file_count = 0
    xml_string = EzXML.readxml(xml_file)
    org_desc = findfirst("//Desc/text()", xml_string)
    if isnothing(org_desc)
        org_desc = findfirst("//Description/text()", xml_string)
    end
    doc = StringDocument(nodecontent(org_desc))
    prepare!(doc, strip_punctuation)
    remove_case!(doc)
    stem!(doc)
    text(doc)
    
    processed_file_count += 1
    print(string("Files successfully processed: ", processed_file_count))
    return doc
end

data_dir = "./data/"
file_list = [data_dir * i for i in readdir(data_dir)]

xml_corpus = Corpus(map(extract_desc, file_list))
update_lexicon!(xml_corpus)
xlm_dtm = DocumentTermMatrix(xml_corpus)

serialize("xml_dtm.jld", xml_dtm)
