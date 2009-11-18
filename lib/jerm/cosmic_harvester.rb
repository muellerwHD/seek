# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'alfresco_harvester'
require 'cosmic_resource'

module Jerm
  class CosmicHarvester < AlfrescoHarvester

    def construct_resource item
      CosmicResource.new(item,@username,@password)
    end

    def project_name
      "Cosmic"
    end
  
  end
end