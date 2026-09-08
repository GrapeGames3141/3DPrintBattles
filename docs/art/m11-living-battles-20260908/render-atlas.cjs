/* Offline concept evidence renderer. DOM checks below validate this HTML composition only, never game behavior. */
const fs = require('fs');
const path = require('path');
const playwrightCandidates = [
  path.resolve(__dirname, '../node_modules/playwright'),
  'C:\\Users\\Tak\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\node_modules\\playwright'
];
const playwrightPath = playwrightCandidates.find(fs.existsSync);
if (!playwrightPath) throw new Error(`No bundled Playwright package found. Checked: ${playwrightCandidates.join(', ')}`);
const { chromium } = require(playwrightPath);

const root = __dirname;
const projectRoot = path.resolve(root, '../../..');
const edge = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const states = ['empty_plan','selected_plan','print_early','print60','rival_print','raw_complete','awaken_in_chamber','launch_from_chamber','step_off_corridor','mat_entry','populated','creature_contact','printer_contact','equipment_fitting','reduced_motion_hc150'];
const sizes = [{name:'941x1672',width:941,height:1672},{name:'576x1024',width:576,height:1024},{name:'720x1280',width:720,height:1280}];
const runStamp = new Date().toISOString().replace(/[:.]/g, '-');
const requested = process.argv.slice(2);
const captureLabel = requested[0] || 'r2';
if (!/^[a-z0-9][a-z0-9_-]*$/i.test(captureLabel)) throw new Error(`Unsafe capture label: ${captureLabel}`);
const selectedStates = requested.slice(1).filter(value => states.includes(value));
const selectedSizes = requested.slice(1).filter(value => sizes.some(size => size.name === value));
const renderStates = selectedStates.length ? selectedStates : states;
const renderSizes = selectedSizes.length ? sizes.filter(size => selectedSizes.includes(size.name)) : sizes;
const captureRoot = path.join(root, 'captures', captureLabel);
const evidenceRoot = path.join(projectRoot, 'build', 'evidence', 'm11-living-battles-20260908', 'atlas-browser');
const userDataDir = path.join(evidenceRoot, `edge-user-data-${runStamp}`);
const fileUrl = `file:///${path.join(root, 'atlas.html').replace(/\\/g, '/')}`;

async function main() {
  fs.mkdirSync(captureRoot, { recursive:true });
  fs.mkdirSync(evidenceRoot, { recursive:true });
  fs.mkdirSync(userDataDir, { recursive:true });
  if (!fs.existsSync(edge)) throw new Error(`Missing required Edge executable: ${edge}`);
  const context = await chromium.launchPersistentContext(userDataDir, { headless:true, executablePath:edge, args:['--disable-gpu', '--no-first-run'] });
  const initialPidQuery = edgeChildPids(process.pid);
  const ledger = { startedAt:new Date().toISOString(), nodePid:process.pid, executable:edge, browserPids:initialPidQuery.pids, browserPidQuery:initialPidQuery, userDataDir, captureLabel, states:renderStates, sizes:renderSizes, cleanup:'pending' };
  fs.writeFileSync(path.join(captureRoot,'render-ledger.json'), JSON.stringify(ledger,null,2));
  try {
    const page = await context.newPage();
    for (const state of renderStates) for (const size of renderSizes) {
      await page.setViewportSize({width:size.width,height:size.height});
      await page.goto(`${fileUrl}?capture=1#${state}`, { waitUntil:'load' });
      await page.evaluate(({ state }) => { window.setConceptState(state); window.dispatchEvent(new Event('resize')); }, { state });
      await page.waitForTimeout(180);
      await page.screenshot({ path:path.join(captureRoot, `${state}-${size.name}.png`), clip:{x:0,y:0,width:size.width,height:size.height} });
    }
    ledger.conceptChecks = await conceptLayoutChecks(page);
  } finally {
    await context.close();
    await new Promise(resolve => setTimeout(resolve, 250));
    ledger.finishedAt = new Date().toISOString();
    const closingPidQuery = edgeChildPids(process.pid);
    ledger.browserPidsRemaining = closingPidQuery.pids;
    ledger.browserPidQueryAfterClose = closingPidQuery;
    if (closingPidQuery.known && ledger.browserPidsRemaining.length === 0) {
      fs.rmSync(userDataDir, { recursive:true, force:true });
      ledger.userDataCleanup = 'removed exact task-owned profile after Edge exited';
    } else {
      ledger.userDataCleanup = closingPidQuery.known ? 'retained: Edge child process still present' : `retained: browser PID query uncertain (${closingPidQuery.error})`;
    }
    ledger.cleanup = 'persistent Edge context closed';
    fs.writeFileSync(path.join(captureRoot,'render-ledger.json'), JSON.stringify(ledger,null,2));
  }
}

async function conceptLayoutChecks(page) {
  async function load(state) {
    await page.setViewportSize({width:941,height:1672});
    await page.goto(`${fileUrl}?capture=1#${state}`, { waitUntil:'load' });
    await page.evaluate(({ state }) => { window.setConceptState(state); window.dispatchEvent(new Event('resize')); }, { state });
  }
  const metricsFor = () => page.evaluate(() => {
    const box = selector => { const rect=document.querySelector(selector).getBoundingClientRect(); return {x:rect.x,y:rect.y,width:rect.width,height:rect.height,bottom:rect.bottom}; };
    const font = selector => Number.parseFloat(getComputedStyle(document.querySelector(selector)).fontSize);
    return {
      unitFont:font('.unit-copy'), handFont:font('.hand-copy'), backFont:font('.back'), leverFont:font('.lever'), resourceFont:font('.rival-resource'), statusFont:font('.status'),
      back:box('.back'), lever:box('.lever'), leverCaption:box('.lever-caption-hc'), friendCaption:box('.f1 .unit-copy'), friendCreature:box('.f1 .creature')
    };
  });
  await load('populated');
  const normal = await metricsFor();
  await load('reduced_motion_hc150');
  const highContrast = await metricsFor();
  const ratios = ['unitFont','handFont','backFont','leverFont','resourceFont','statusFont'].reduce((result, key) => {
    result[key] = Number((highContrast[key] / normal[key]).toFixed(2));
    return result;
  }, {});
  const checks = {
    kind:'concept-only DOM layout checks; not game evidence',
    ratios,
    captionClearOfCreature: highContrast.friendCaption.y >= highContrast.friendCreature.bottom,
    captionClearanceDesignPx: Number((1018 - highContrast.friendCaption.bottom).toFixed(2)),
    captionAboveMatRim: highContrast.friendCaption.bottom <= 1008,
    backHitDesignPx: normal.back.height,
    leverHitDesignPx: normal.lever.height,
    leverCaptionBottomDesignPx: Number(highContrast.leverCaption.bottom.toFixed(2))
  };
  const ratiosPass = Object.values(ratios).every(value => value === 1.5);
  const geometryPass = checks.captionClearOfCreature && checks.captionAboveMatRim && checks.backHitDesignPx >= 79 && checks.leverHitDesignPx >= 92 && checks.leverCaptionBottomDesignPx <= 1630;
  checks.pass = ratiosPass && geometryPass;
  if (!checks.pass) throw new Error(`Concept-only DOM layout check failed: ${JSON.stringify(checks)}`);
  return checks;
}
function edgeChildPids(parentPid) {
  try {
    const { execFileSync } = require('child_process');
    const query = `$ErrorActionPreference = 'Stop'; Get-CimInstance Win32_Process -Filter \"ParentProcessId=${parentPid}\" | Where-Object { $_.Name -ieq 'msedge.exe' } | Select-Object -ExpandProperty ProcessId`;
    return {known:true, pids:execFileSync('powershell.exe', ['-NoProfile','-Command',query], { encoding:'utf8' }).trim().split(/\s+/).filter(Boolean).map(Number)};
  } catch (error) { return {known:false, pids:[], error:String(error.message || error)}; }
}
main().catch(error => { console.error(error.stack || error); process.exitCode=1; });
