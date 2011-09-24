
require 'savon'

# Simple wrapper for interacting with the OLS (Ontology Lookup Service - http://www.ebi.ac.uk/ontology-lookup/) 
# database (created and managed by the EBI).
#
# @author Darren Oakley
module OLS
  # Error class for when we can't find a given ontology term.
  class OntologyTermNotFoundError < StandardError; end


end
