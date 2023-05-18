FROM node:16-alpine as client-builder

COPY ./client /client
WORKDIR /client
RUN npm install

RUN echo "VITE_APIURL=/api/v1" > .env.production
RUN npm run build

FROM python:3.11-alpine as runner

LABEL org.opencontainers.image.source=https://github.com/Donkie/Spoolman
LABEL org.opencontainers.image.description="Keep track of your inventory of 3D-printer filament spools."
LABEL org.opencontainers.image.licenses=MIT

# Add local user so we don't run as root
RUN adduser -D app
USER app

RUN python -m venv /home/app/.venv

ENV PATH="/home/app/.venv/bin:${PATH}"

# Copy and install app
COPY --chown=app:app spoolman /home/app/spoolman/spoolman
COPY --chown=app:app pyproject.toml /home/app/spoolman/
COPY --chown=app:app requirements.txt /home/app/spoolman/
COPY --chown=app:app README.md /home/app/spoolman/

WORKDIR /home/app/spoolman
RUN pip install -e .

# Copy built client
COPY --chown=app:app --from=client-builder /client/dist /home/app/spoolman/client/dist

# Run command
EXPOSE 8000
ENTRYPOINT ["uvicorn", "spoolman.main:app"]
CMD ["--host", "0.0.0.0", "--port", "8000"]