.PHONY: dev frontend backend test
frontend:
	cd frontend && bun run dev &
backend:
	cd backend && uvicorn app.main:app --reload &

dev: frontend backend

test:
	bun test && pytest -q
