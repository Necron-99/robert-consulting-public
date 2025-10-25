# Plex Recommendations Project
# This module manages the Plex recommendations project infrastructure

module "plex_recommendations" {
  source = "./modules/plex-project"
  
  project_name = "plex-recommendations"
  environment  = "production"
}
