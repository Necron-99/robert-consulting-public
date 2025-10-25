# Test configuration for Plex Recommendations Project
# This will test the plex-project module in the root account

# Plex Recommendations Module
module "plex_recommendations" {
  source = "./modules/plex-project"
  
  project_name = "plex-recommendations"
  environment  = "production"
}
