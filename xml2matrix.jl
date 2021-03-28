using EzXML
using TextAnalysis
using Serialization

function extract_name(xml_file)
    xml_string = EzXML.readxml(xml_file)
    test_string = findfirst("//Filer
                             //BusinessName
                             //BusinessNameLine1Txt/text()", xml_string)
    if !isnothing(test_string)
        org_name = nodecontent(test_string)
    else
        org_name = ""
    end
    return org_name
end

function extract_revenue(xml_file)
    xml_string = EzXML.readxml(xml_file)
    test_string = findfirst("//ReturnData
                             //IRS990EZ
                             //TotalRevenueAmt/text()", xml_string)
    if isnothing(test_string)
        test_string = findfirst("//ReturnData
                                 //IRS990
                                 //RevenueAmt/text()", xml_string)
    end
    if !isnothing(test_string)
        org_rev = nodecontent(test_string)
    else
        org_rev = ""
    end
    return org_rev
end

function extract_desc(xml_file)
    xml_string = EzXML.readxml(xml_file)
    test_string = findfirst("//Desc/text()", xml_string)
    if isnothing(test_string)
        test_string = findfirst("//Descriptions/text()", xml_string)
    elseif isnothing(test_string)
        test_string = findfirst("//ActivityOrMissionDesc")
    elseif isnothing(test_string)
        test_string = findfirst("//PrimaryExemptPurposeTxt/text()")
    elseif isnothing(test_string)
        test_string = findfirst("//ExplanationTxt/text()")
    elseif isnothing(test_string)
        test_string = findfirst("//DescriptionProgramSrvcAccomTxt/text()")
    end
    if !isnothing(test_string)
        # org_desc = nodecontent(test_string)
        ######### TextAnalysis processing within function START ###########
        org_desc = StringDocument(nodecontent(test_string))
        prepare!(org_desc, strip_punctuation)
        remove_case!(org_desc)
        stem!(org_desc)
        return org_desc
    else
        org_desc = StringDocument("")
    end
        # doc = StringDocument(nodecontent(org_desc))
        # prepare!(doc, strip_punctuation)
        # remove_case!(doc)
        # stem!(doc)
        # text(doc)
        # return doc
    # end
end

function generate_xml_dict(file)
    #if !isnothing(extract_desc(file))
        Dict("file"     => file,
            "org_name" => extract_name(file),
            "org_rev"  => extract_revenue(file),
            "org_desc" => extract_desc(file))
    #end
end

dict_array = map(generate_xml_dict, readdir("2019", join = true))
xml_doc_array = [i["org_desc"] for i in dict_array]
xml_corpus = Corpus(xml_doc_array)
update_lexicon!(xml_corpus)
xml_dtm = dtm(xml_corpus)

println(string("Total Dictionary entries: ", length(dict_array)))
println(string("Total descriptions extracted: ", length(xml_corpus)))
serialize("../xml_dtm.jld", xml_dtm)
serialize("../xml_dict.jld", xml_dict)


## SINGLE FILE TESTING ---------------------------------------------------------
test_file = readdir()[1]
test_xml_dict = Dict("file" => test_file,
                "org_name" => extract_name(test_file),
                "org_rev"  => extract_revenue(test_file),
                "org_desc" => extract_desc(test_file))