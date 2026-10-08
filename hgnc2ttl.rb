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

  def identifier(str)
    puts triple(@subject, "dct:identifier", quote(str))
  end

  def description(str)
    puts triple(@subject, "dct:description", quote(str))
  end

  def location(str)
    puts triple(@subject, "obo:so_part_of", quote(str)) unless str.empty?
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
      puts triple(id_uri, "dct:identifier", quote(id))
    end
  end

  def unquote(str)
    str.sub(/\A"(.*)"\z/m, '\1')
  end

  def split_ids(ids)
    if ids and not ids.empty?
      unquote(ids).split('|').map(&:strip)
    else
      []
    end
  end

  def status(str)
    puts triple(@subject, "skos:historyNote", quote(str))
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
  7 alias_symbol                 FLJ23569
  8 alias_name                   "NCRNA00181|A1BGAS|A1BG-AS"
  9 prev_symbol
 10 prev_name
 11 gene_group                   Immunoglobulin like domain containing
 12 gene_group_id                594
 13 date_approved_reserved       1989-06-30
 14 date_symbol_changed
 15 date_name_changed
 16 date_modified                2023-01-20
 17 entrez_id                    1
 18 ensembl_gene_id              ENSG00000121410
 19 vega_id                      OTTHUMG00000183507
 20 ucsc_id                      uc002qsd.5
 21 ena
 22 refseq_accession             NM_130786
 23 ccds_id                      CCDS12976
 24 uniprot_ids                  P04217
 25 pubmed_id                    2591067
 26 mgd_id                       MGI:2152878
 27 rgd_id                       RGD:69417
 28 lsdb
 29 cosmic
 30 omim_id                      138670
 31 mirbase
 32 homeodb
 33 snornabase
 34 bioparadigms_slc
 35 orphanet
 36 pseudogene.org
 37 horde_id
 38 merops                       I43.950
 39 imgt
 40 iuphar
 41 kznf_gene_catalog
 42 mamit-trnadb
 43 cd
 44 lncrnadb
 45 enzyme_id
 46 intermediate_filament_db
 47 rna_central_id
 48 lncipedia
 49 gtrnadb
 50 agr                          HGNC:5
 51 mane_select                  "ENST00000263100.8|NM_130786.4"
 52 gencc
=end

  def parse_line(line)
    ary = line.strip.split("\t")
    id = ary[0].sub('HGNC:', '')
    @subject = "<http://identifiers.org/hgnc/#{id}>"
    type("obo:SO_0000704")
    type("m2r:Gene")
    label(ary[1])
    identifier(id)
    description(ary[2])
    status(ary[5])
    location(ary[6])
    alt_label(ary[7])
    alt_label(ary[8])
    see_also("ncbigene", ary[17])
    see_also("ensembl", ary[18])
    see_also("ena.embl", ary[21])
    see_also("insdc", ary[21])
    see_also("refseq", ary[22])
    see_also("ccds", ary[23])
    see_also("uniprot", ary[24])
    reference("pubmed", ary[25])
    see_also("mgi", ary[26])
    see_also("rgd", ary[27].sub('RGD:','')) if ary[27]
    see_also("lrg", ary[28])
    see_also("mim", ary[30])
    see_also("mirbase", ary[31])
    see_also("orphanet", ary[35])
    see_also("iuphar.receptor", ary[40])
    see_also("ec-code", ary[45])
    puts
  end
end


header = ARGF.gets

HGNC2TTL.new(ARGF)


