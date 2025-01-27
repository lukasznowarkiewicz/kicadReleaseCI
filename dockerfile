# Dockerfile
FROM --platform=linux/amd64 kicad/kicad:8.0.8

# Switch to root so we can install packages and set permissions
USER root

#Install required dependencies
RUN apt-get update && apt-get install -y pdftk

# Copy the script
COPY generate_kicad_outputs.sh /usr/local/bin/generate_kicad_outputs.sh

# Make it executable
RUN chmod +x /usr/local/bin/generate_kicad_outputs.sh

# (Optional) install anything else you need here (e.g. zip if not already installed)
# RUN apt-get update && apt-get install -y zip


# Switch back to the user used by the base image (if necessary).
# In some KiCad Docker images, that user is named 'kicad'. Double-check by reading the Dockerfile or 
# using "id" inside the container. If you’re unsure, you can just stay as root or do:
# USER kicad

ENTRYPOINT ["/usr/local/bin/generate_kicad_outputs.sh"]


