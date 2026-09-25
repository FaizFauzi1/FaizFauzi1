import ws from 'k6/ws';
import { check } from 'k6';
import { Config } from '../config/config.js';

/**
 * Scenario: Supabase Realtime WebSocket Connection & Subscription
 * Tests the Realtime Phoenix WebSocket cluster connection capacity and heartbeat:
 * 1. Establish WebSocket handshake with Supabase Realtime
 * 2. Join a table channel ('realtime:public:appointments')
 * 3. Send Phoenix heartbeat
 * 4. Gracefully disconnect
 */
export function scenarioRealtime() {
  const url = Config.realtimeWsUrl();

  const res = ws.connect(url, {}, function (socket) {
    socket.on('open', () => {
      // 1. Join Realtime topic
      const joinMsg = JSON.stringify({
        topic: 'realtime:public:appointments',
        event: 'phx_join',
        payload: {
          config: {
            broadcast: { self: false },
            presence: { key: '' },
            postgres_changes: [
              { event: '*', schema: 'public', table: 'appointments' }
            ]
          }
        },
        ref: '1'
      });
      socket.send(joinMsg);

      // 2. Send heartbeat
      socket.setTimeout(() => {
        const heartbeat = JSON.stringify({
          topic: 'phoenix',
          event: 'heartbeat',
          payload: {},
          ref: '2'
        });
        socket.send(heartbeat);
      }, 1000);

      // 3. Close connection after 3 seconds
      socket.setTimeout(() => {
        socket.close();
      }, 3000);
    });

    socket.on('error', (e) => {
      console.error('Realtime WS error:', e.error());
    });
  });

  check(res, {
    'realtime ws handshake 101': (r) => r && r.status === 101,
  });
}
