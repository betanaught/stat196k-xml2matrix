# CSUS STAT 196K Assignment: H XML To Matrix

- Apply natural language processing (NLP) techniques to convert unstructured text to a numeric matrix
- Extract interesting data from XML documents
---
title: H Assigment - XML to Matrix
author: Brendan Wakefield
date: 28 March 2021
---
# Questions

1. __How many fo the returns were you able to process?__
OK, I cheated here by returning empty strings for my extracted content i.e.,
```
if isnothing(org_desc)
    org_desc = ""
end
```
so, this means I was "able" to process all of them. My guess is that, ideally, I would have had some catch in place to only include dictionaries in my `dict_array` where extrations of the `org_desc` were successful (since, the goal is to cluster the organizations based on their descriptions and then compare that information to the other quantitative metrics). However, I couldn't get around the issue that `StingDocument()` cannot accept `nothing`, and I wasn't able to find a way to filter the dictionaries out when
```
isnothing(dict_array[i]["org_desc"]) == true
```
(huh, as I wrote that last phrase as pseudocode, I might have figured out how to do it??). Anyway, I think I could improve the code if I just extract the descriptions as test strings in each dictionary, and then do the `StingDocument` and other `TextAnalysis` processing later, after I've been able to filter out dictionaries where `"org_desc" == nothing`.

2. __Show and interpret one explicit example of what you extracted from one tax return, including the text description before and after processing.__
Again, processing the organization description *after* extracting the content might have been better, as opposed to doing the extraction and processing both within the `extract_desc()` function.

Before processing description:

"THE SHAW UNIVERSITY IS A COEDUCATIONAL INSTITUTION OF LIBERAL ARTS, OFFERING UNDERGRADUATE DEGREES AND A MASTERS OF DIVINITY DEGREE, MASTERS OF RELIGIOUS EDUCATION AND A MASTER OF SCIENCE IN CURRICULUM AND INSTRUCTION WITH A CONCENTRATION IN EARLY CHILDHOOD EDUCATION. THE UNIVERSITY PROVIDES STUDENT AID TO QUALIFIED STUDENTS WHO EXPRESS A FINANCIAL NEED IN ORDER TO COMPLETE THEIR EDUCATION. THERE ARE APPROXIMATELY 1,775 FULL-TIME AND PART-TIME STUDENTS. THE UNIVERSITY ALSO OFFERS STUDENT HOUSING."


After processing description:

"the shaw univers is a coeduc institut of liber art offer undergradu degre and a master of divin degre master of religi educ and a master of scienc in curriculum and instruct with a concentr in earli childhood educ the univers provid student aid to qualifi student who express a financi need in order to complet their educ there are approxim 1775 fulltim and parttim student the univers also offer student hous"

3. __What are the dimensions of your term document matrix?__

See summary output below:
475575 x 189851 SparseArrays.SparseMatrixCSC{Int64,Int64} with 8778354 stored 

4. __How long did your program take to run? (Less than 30 minutes is easily attainable, but no problem if it takes longer, either__
In all, the code ran in about 25 minutes. The longest step was the creation of my array of dictionaries (`dict_array`), but I noticed this process only ran on a single vCPU. I tried to use `Distributed` and add `addproc(3)`, but when I ran the same command with `pmap` I noticed that the process still only ran in a single vCPU (shown in `top`). I would love to figure out how to run this with `Distributed` and potentially shorten the time (otherwise, the extra memory is the only benefit of using the `t2.xlarge` instance.

```
$ time sudo yum install emacs
> real 0m41.427s

$ time aws s3 cp s3://stat196k-data-examples/2019irs990.zip ./ \
  --no-sign-request
> real 30.612s

$ time unzip 2019irs990.zip 
> real	3m35.219s

$ ls 2019 | wc
> 475575  475575 14267250
```
```
## @time dict_array = map(generate_xml_dict, readdir("2019", join = true))
## 1232.473557 seconds (400.15 M allocations: 26.605 GiB, 0.70% gc time)

## Used only 1 vCPU (100% of a single process in top) and ~15% memory
## TODO: using Distributed; addprocs(3)
## Dang, could not get my big processing step to run on all 4 vCPUS:
julia> @time pmap(dict_array = map(generate_xml_dict, readdir("2019",
                                                              join = true)))
## But interestingly, the %MEM was ~5....??

julia> @time xml_doc_array = [i["org_desc"] for i in dict_array]
julia> 0.224779 seconds (75.20 k allocations: 7.599 MiB)

julia> @time xml_corpus = Corpus(xml_doc_array)
julia> 0.018077 seconds (31.64 k allocations: 1.731 MiB)

julia> @time update_lexicon!(xml_corpus)
126.838327 seconds (261.75 M allocations: 18.145 GiB, 4.14% gc time)

julia> @time xml_dtm = dtm(xml_corpus)
129.372590 seconds (265.01 M allocations: 18.489 GiB, 3.67% gc time)
475575×189851 SparseArrays.SparseMatrixCSC{Int64,Int64}
with 8778354 stored entries:
  [215   ,      1]  =  1
  [802   ,      1]  =  1
  [1128  ,      1]  =  1
  [2354  ,      1]  =  2
  [2372  ,      1]  =  1
  [5138  ,      1]  =  1
  [5565  ,      1]  =  1
  [7643  ,      1]  =  1
  [12345 ,      1]  =  1
  [15267 ,      1]  =  1
  [17931 ,      1]  =  2
  [19362 ,      1]  =  1
  [21592 ,      1]  =  1
  [25499 ,      1]  =  4
  ⋮
  [298129, 189847]  =  1
  [330203, 189847]  =  1
  [341243, 189847]  =  1
  [351117, 189847]  =  1
  [373306, 189847]  =  1
  [408883, 189847]  =  2
  [427312, 189847]  =  6
  [438526, 189847]  =  1
  [453194, 189847]  =  1
  [453210, 189847]  =  1
  [471065, 189847]  =  1
  [471065, 189848]  =  1
  [32365 , 189849]  =  1
  [227911, 189850]  =  2
  [69094 , 189851]  =  1
```
```
$ scp -i ../../keys/stat_user-02-07-2021.pem \
  ec2-user@34.235.162.248:/home/ec2-user/*.jld results/
dict_array.jld              100%  126MB   7.1MB/s   00:17    
xml_corpus.jld              100%   83MB   6.6MB/s   00:12    
xml_dtm.jld                 100%  135MB   7.3MB/s   00:18 
```
# ------------------------------------------------------------------------------
# Julia Code
```julia
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
serialize("xml_dtm.jld", xml_dtm)
serialize("xml_dict.jld", xml_dict)
serialize("xml_corpus.jld", xml_corpus)
```