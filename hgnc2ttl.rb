#!/usr/bin/env ruby

module RDFSupport
  def quote(str)
    return str.gsub('\\', '\\\\').gsub("\t", '\\t').gsub("\n", '\\n').gsub("\r", '\\r').gsub('"', '\\"').inspect
  end

  def triple(s, p, o)
    return [s, p, o].join("\t") + " ."
  end

  def po(p, o, e = ';')
    s = ''
    return [s, p, o, e].join("\t")
  end
end

class HGNC2TTL

  include RDFSupport

  PREFIXES = [
    ["@prefix", "rdf:", "<http://www.w3.org/1999/02/22-rdf-syntax-ns#>"],
    ["@prefix", "rdfs:", "<http://www.w3.org/2000/01/rdf-schema#>"],
    ["@prefix", "dct:", "<http://purl.org/dc/terms/>"],
  ]

  def label(str)
    puts triple(@subject, "rdfs:label", quote(str))
  end

  def description(str)
    puts triple(@subject, "dct:description", quote(str))
  end

  def reference(db, id)
    xref(db, id, "dct:references")
  end

  def xref(db, ids, predicate = 'rdfs:seeAlso')
    if ids and not ids.empty?
      ids.gsub('"','').split('|').each do |id|
        uri = "<http://identifiers.org/#{db}/#{id}>"
        puts triple(@subject, predicate, uri)
        puts triple(uri, "rdf:type", "<http://identifiers.org/#{db}>")
      end
    end
  end

  def initialize(io)
    PREFIXES.each do |ary|
      puts triple(*ary)
    end
    puts
    io.each_line do |line|
      parse_line(line)
    end
  end

=begin
  0 hgnc_id                      HGNC:5
  1 symbol                       A1BG
  2 name                         alpha-1-B glycoprotein
  3 locus_group                  protein-coding gene
  4 locus_type                   gene with protein product
  5 status                       Approved
  6 location                     19q13.43
  7 location_sortable            19q13.43
  8 alias_symbol                 
  9 alias_name                   
 10 prev_symbol                  
 11 prev_name                    
 12 gene_family                  Immunoglobulin like domain containing
 13 gene_family_id               594
 14 date_approved_reserved       1989-06-30
 15 date_symbol_changed          
 16 date_name_changed            
 17 date_modified                2015-07-13
 18 entrez_id                    1
 19 ensembl_gene_id              ENSG00000121410
 20 vega_id                      OTTHUMG00000183507
 21 ucsc_id                      uc002qsd.5
 22 ena                          
 23 refseq_accession             NM_130786
 24 ccds_id                      CCDS12976
 25 uniprot_ids                  P04217
 26 pubmed_id                    2591067
 27 mgd_id                       MGI:2152878
 28 rgd_id                       RGD:69417
 29 lsdb                         
 30 cosmic                       A1BG
 31 omim_id                      138670
 32 mirbase                      
 33 homeodb                      
 34 snornabase                   
 35 bioparadigms_slc             
 36 orphanet                     
 37 pseudogene.org               
 38 horde_id                     
 39 merops                       I43.950
 40 imgt                         
 41 iuphar                       
 42 kznf_gene_catalog            
 43 mamit-trnadb                 
 44 cd                           
 45 lncrnadb                     
 46 enzyme_id                    
 47 intermediate_filament_db     
 48 rna_central_ids              

=end


  def parse_line(line)
    ary = line.strip.split("\t")
    @subject = "<http://identifiers.org/hgnc/#{ary[0].sub('HGNC:', '')}>"
    label(ary[1])
    description(ary[2])
    xref("ncbigene", ary[18])
    xref("ensembl", ary[19])
    xref("ena.embl", ary[22])
    xref("refseq", ary[23])
    xref("ccds", ary[24])
    xref("uniprot", ary[25])
    reference("pubmed", ary[26])
    xref("mgi", ary[27])
    xref("rgd", ary[28].sub('RGD:','')) if ary[28]
    xref("lrg", ary[29])
    xref("omim", ary[31])
    xref("mirbase", ary[32])
    xref("orphanet", ary[36])
    xref("iuphar.receptor", ary[41])
    xref("ec-code", ary[46])
    puts
  end
end


header = ARGF.gets

HGNC2TTL.new(ARGF)


