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
    ["@prefix", "skos:", "<http://www.w3.org/2004/02/skos/core#>"],
    ["@prefix", "obo:", "<http://purl.obolibrary.org/obo/>"],
    ["@prefix", "m2r:", "<http://med2rdf.org/ontology/med2rdf#>"],
  ]

  def type(uri)
    puts triple(@subject, "rdf:type", uri)
  end

  def label(str)
    puts triple(@subject, "rdfs:label", quote(str))
  end

  def description(str)
    puts triple(@subject, "dct:description", quote(str))
  end

  def location(str)
    puts triple(@subject, "obo:so_part_of", quote(str))
  end

  def alt_label(str)
    alias_names(str, "skos:altLabel")
  end

  def alias_names(str, predicate = "skos:altLabel")
    split_ids(str).each do |item|
      unless item.empty?
        puts triple(@subject, predicate, quote(item))
      end
    end
  end

  def see_also(db, ids)
    xref(db, ids, "rdfs:seeAlso")
  end

  def reference(db, ids)
    xref(db, ids, "dct:references")
  end

  def xref(db, str, predicate = 'rdfs:seeAlso')
    split_ids(str).each do |id|
      if db == "lrg"
        next unless id[/^LRG_/]
      end
      db_uri = "<http://identifiers.org/#{db}>"
      id_uri = "<http://identifiers.org/#{db}/#{id}>"
      puts triple(@subject, predicate, id_uri)
      puts triple(id_uri, "rdf:type", db_uri)
    end
  end

  def split_ids(ids)
    if ids and not ids.empty?
      ids.gsub('"','').split('|')
    else
      []
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
  8 alias_symbol                 FLJ23569
  9 alias_name                   "NCRNA00181|A1BGAS|A1BG-AS"
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
    type("obo:SO_0000704")
    type("m2r:Gene")
    label(ary[1])
    description(ary[2])
    location(ary[6])
    alt_label(ary[8])
    alt_label(ary[9])
    see_also("ncbigene", ary[18])
    see_also("ensembl", ary[19])
    see_also("ena.embl", ary[22])
    see_also("refseq", ary[23])
    see_also("ccds", ary[24])
    see_also("uniprot", ary[25])
    reference("pubmed", ary[26])
    see_also("mgi", ary[27])
    see_also("rgd", ary[28].sub('RGD:','')) if ary[28]
    see_also("lrg", ary[29])
    see_also("omim", ary[31])
    see_also("mirbase", ary[32])
    see_also("orphanet", ary[36])
    see_also("iuphar.receptor", ary[41])
    see_also("ec-code", ary[46])
    puts
  end
end


header = ARGF.gets

HGNC2TTL.new(ARGF)


