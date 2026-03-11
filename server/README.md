# Attachments Node Server

This small Node/Express server is intended to:

- Serve a small UI at `/` for running dataset prep and short trainings. 
- Serve the repo's web-app if present under `/app`.
- Provide lightweight endpoints to run `ml/data_prep.py` and `ml/train.py` for quick validation.

Run locally:

```
cd server
npm install
npm start
```

Build docker image:

```
docker build -t attachments-server .
docker run -p 3000:3000 attachments-server
```

Notes:
- Designed for low-power deployment (alpine base). Use swap or small GPUs as available.
- The endpoints run Python scripts as child processes; ensure Python & deps are installed.
