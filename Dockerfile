FROM continuumio/miniconda3:latest

# Set environment variable for MONAI bundle
ENV MONAI_BUNDLE_URL="https://github.com/Project-MONAI/model-zoo/releases/download/hosting_storage_v1/spleen_ct_segmentation_v0.3.8.zip"

# Install system dependencies with proper cleanup
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
    git \
    build-essential \
    cmake \
    pigz \
    libsm6 \
    libxrender-dev \
    libxext6 \
    ffmpeg \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY docker-entrypoint.sh ./
COPY seg_app ./seg_app
COPY environment.yml ./

RUN chmod 777 ./docker-entrypoint.sh

# Create updated Python environment
RUN conda env create -f ./environment.yml
RUN echo "source activate $(head -1 ./environment.yml | cut -d' ' -f2)" > ~/.bashrc
ENV PATH /opt/conda/envs/$(head -1 ./environment.yml | cut -d' ' -f2)/bin:$PATH

# Download MONAI bundle and extract model.ts file
RUN mkdir -p -m777 ./zip_tmp \
    && wget --directory-prefix ./zip_tmp ${MONAI_BUNDLE_URL} \
    && unzip ./zip_tmp/*.zip -d ./zip_tmp/ \
    && cp ./zip_tmp/*/models/model.ts ./ \
    && rm -rf ./zip_tmp \
    && chmod 777 ./model.ts

CMD ["./docker-entrypoint.sh"]