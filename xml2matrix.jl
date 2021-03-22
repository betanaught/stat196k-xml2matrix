using EzXML
using TextAnalysis
using Serialization

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
    
    return doc
end

function main()
    data_dir = "./data/"
    file_list = [data_dir * i for i in readdir(data_dir)]

    xml_corpus = Corpus(map(extract_desc, file_list))
    update_lexicon!(xml_corpus)
    xml_dtm = dtm(xml_corpus)

    xml_dict = Dict()
    for file in file_list
        xml_dict[extract_name(file)] = extract_size(file)
    end
    xml_dict

    println(string("Total Dictionary entries: ", length(xml_dict)))
    println(string("Total descriptions extracted: ", length(xml_corpus)))
    serialize("xml_dtm.jld", xml_dtm)
    serialize("xml_dict.jld", xml_dict)
end

main()