FROM node:22-bookworm AS client-builder

WORKDIR /app/client

COPY client/package*.json ./
RUN npm install

COPY client/ ./
RUN npm run build


FROM golang:1.26-bookworm AS server-builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
COPY --from=client-builder /app/client/dist ./client/dist

RUN CGO_ENABLED=0 GOOS=linux go build -o /wacalls ./cmd/server


FROM debian:bookworm-slim

WORKDIR /app

RUN mkdir -p /data

COPY --from=server-builder /wacalls /app/wacalls
COPY --from=server-builder /app/client/dist /app/client/dist

EXPOSE 8080

CMD ["/app/wacalls", "-addr", ":8080", "-db", "/data/wacalls.db", "-static", "/app/client/dist"]
