
import { FastifyInstance } from 'fastify';
import { healthCheck } from '../controller/health';

export default async function (server: FastifyInstance) {
  server.get('/health', healthCheck);
}
