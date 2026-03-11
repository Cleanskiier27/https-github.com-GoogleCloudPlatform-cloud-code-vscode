#!/usr/bin/env node
// Placeholder avatar world runner - long-running process
console.log('avatar world starting...');
let i=0;
setInterval(()=>{
  console.log('avatar tick', ++i);
}, 2000);
process.on('SIGINT', ()=>{ console.log('avatar shutting down'); process.exit(0); });
