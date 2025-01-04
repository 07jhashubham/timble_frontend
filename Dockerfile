# Build environment
FROM rustlang/rust:nightly-bullseye as builder

# Install cargo-binstall, which makes it easier to install other
# cargo extensions like cargo-leptos
RUN wget https://github.com/cargo-bins/cargo-binstall/releases/latest/download/cargo-binstall-x86_64-unknown-linux-musl.tgz \
    && tar -xvf cargo-binstall-x86_64-unknown-linux-musl.tgz \
    && cp cargo-binstall /usr/local/cargo/bin \
    && cargo binstall cargo-leptos -y

# Install the specific version of wasm-bindgen-cli
RUN cargo install -f wasm-bindgen-cli --version 0.2.95

# Add the WASM target
RUN rustup target add wasm32-unknown-unknown

# Set working directory
RUN mkdir -p /app
WORKDIR /app
COPY . .

# Lock the `wasm-bindgen` dependency to 0.2.95 in Cargo.toml
RUN sed -i 's/wasm-bindgen = ".*"/wasm-bindgen = "=0.2.95"/' Cargo.toml

# Build the app
RUN cargo leptos build --release -vv



# Runtime environment
FROM debian:bookworm-slim as runtime

WORKDIR /app

# Install necessary dependencies
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Copy files from the builder stage
COPY --from=builder /app/target/release/leptos_start /app/
COPY --from=builder /app/target/site /app/site
COPY --from=builder /app/Cargo.toml /app/

# Environment variables
ENV RUST_LOG="info"
ENV LEPTOS_SITE_ADDR="0.0.0.0:8080"
ENV LEPTOS_SITE_ROOT="site"

EXPOSE 8080

# Run the server
CMD ["/app/leptos_start"]