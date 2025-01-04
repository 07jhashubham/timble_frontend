# Start with a Rust nightly environment
FROM rustlang/rust:nightly-alpine as builder

# Install necessary tools and dependencies
RUN apk update && \
    apk add --no-cache bash curl npm libc-dev binaryen openssl-dev protoc protobuf-dev gcc git g++ make

# Install sass
RUN npm install -g sass

# Install cargo-leptos
RUN curl --proto '=https' --tlsv1.2 -LsSf https://github.com/leptos-rs/cargo-leptos/releases/download/0.2.5/cargo-leptos-installer.sh | sh

# Add the WASM target
RUN rustup target add wasm32-unknown-unknown

# Set working directory and copy files
WORKDIR /work
COPY . .

# Build the project with Leptos
RUN ls -l /work && cargo leptos build --release -vv

# Prepare the runner image
FROM rustlang/rust:nightly-alpine as runner

WORKDIR /app
COPY --from=builder /work/target/release/leptos-railway /app/
COPY --from=builder /work/target/site /app/site
COPY --from=builder /work/Cargo.toml /app/

EXPOSE $PORT
ENV LEPTOS_SITE_ROOT=./site

CMD ["/app/leptos-railway"]