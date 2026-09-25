const url = "https://lqvsavyfbnarwsunbfzm.supabase.co/rest/v1";
const key = "sb_publishable_tAUtEvgarcJEtlo50Bdtxg_m9SVzy_5";
const headers = { apikey: key, Authorization: "Bearer " + key };

async function main() {
  const r = await fetch(url + "/vendor_services?select=category&limit=100", { headers });
  const d = await r.json();
  const set = new Set(d.map(x => x.category));
  console.log("Categories in vendor_services:", Array.from(set));
}
main();
