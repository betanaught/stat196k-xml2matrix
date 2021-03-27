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
        org_name = nothing
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
        org_rev = nothing
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
        org_desc = nodecontent(test_string)
    else
        org_desc = nothing
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
    Dict("file"     => file,
         "org_name" => extract_name(file),
         "org_rev"  => extract_revenue(file),
         "org_desc" => extract_desc(file))
    end
end

dict_array = map(generate_xml_dict, readdir())

function main(data_dir = "./data/")
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
    serialize("../xml_dtm.jld", xml_dtm)
    serialize("../xml_dict.jld", xml_dict)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

## SINGLE FILE TESTING ---------------------------------------------------------
test_file = readdir()[1]
xml_dict = Dict("file" => test_file,
                "org_name" => extract_name(test_file),
                "org_rev"  => extract_revenue(test_file),
                "org_desc" => extract_desc(test_file))