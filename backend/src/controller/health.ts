
import { FastifyRequest, FastifyReply } from 'fastify';

export const healthCheck = async (request: FastifyRequest, reply: FastifyReply) => {
  return { status: 'ok' };
};
