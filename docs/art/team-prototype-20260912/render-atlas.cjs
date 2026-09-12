/* Offline concept renderer. DOM checks validate this HTML composition only, never runtime behavior. */
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const playwrightCandidates = [path.resolve(__dirname, '../node_modules/playwright'), 'C:\\Users\\Tak\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\node_modules\\playwright'];
const playwrightPath = playwrightCandidates.find(fs.existsSync);
if (!playwrightPath) throw new Error(`Missing bundled Playwright: ${playwrightCandidates.join(', ')}`);
const { chromium } = require(playwrightPath);

const root = __dirname;
const projectRoot = path.resolve(root, '../../..');
const edge = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const states = ['teamvalid','teaminvalid','team-empty','team-one','supportkit','supportkit-excluded','workshop-prototype-nav','preflight-error','recovery','focus-sheet','reduced-motion','choosefirstprint','populatedPlan','preflight-empty','first-entry-active','combined-second-plan','second-print','reserve-1-entry','third-plan-behind-gear','equipment-auto-fit','reserve-2-entry','swap-and-attack','auto-replacement','printEarly','print60','rawcomplete','awaken','reserveentry','activewaiting','activewaitingrun','win-result-m2','loss-result-m2','draw-result-m2','finaldefeat','Draw','guaranteedstarterreceipt','starter-choice','starter-inspect','starter-voucher','starter-print-early','starter-print-60','starter-rawcomplete','starter-awaken','HC150-RM'];
const sizes = [{ name:'576x1024', width:576, height:1024 }, { name:'720x1280', width:720, height:1280 }, { name:'720x1600', width:720, height:1600 }];
const expectedFigures = { teamvalid:0, teaminvalid:0, supportkit:0, choosefirstprint:6, populatedPlan:6, selectedsupport:6, printEarly:5, print60:5, rawcomplete:5, awaken:5, reserveentry:6, activewaiting:5, swap:6, attack:6, autoreplacement:6, finaldefeat:6, Draw:6, guaranteedstarterreceipt:0, 'HC150-RM':6 };
const requiredAssets = [
  'BA-R1-team-autobattle-chassis-text-free-v1.png', 'TM-R1-team-support-workbench-text-free-v1.png',
  '../../../assets/cards/support_card_back_source_v1.png', '../../../assets/cards/support_cards_resources_landscape_v2.png', '../../../assets/cards/support_cards_offense_landscape_v2.png', '../../../assets/ui/physical_ui/m3/BA-05-result-receipt-v4.png',
  '../../../assets/ui/physical_ui/forge-continuity/enclosed-forge-static-master-v1.png', '../../../assets/ui/physical_ui/m1-r2/starter-blueprint-desk-v4.png', '../../../assets/ui/physical_ui/forge-continuity/carriage-guide-v1.png', '../../../assets/ui/physical_ui/forge-continuity/carriage-head-v1.png',
  '../../../assets/creatures/2d/battle-facing/cinderpaw_battle_facing_4x2.png', '../../../assets/creatures/2d/battle-facing/aquafin_battle_facing_4x2.png',
  '../../../assets/creatures/2d/battle-facing/mossmunk_battle_facing_4x2.png', '../../../assets/creatures/2d/voltwig_sprite_sheet.png'
];
const requested = process.argv.slice(2);
const label = requested[0] || 'v1';
if (!/^[a-z0-9][a-z0-9_-]*$/i.test(label)) throw new Error('Unsafe capture label');
const requestedStates = requested.slice(1).filter(value => states.includes(value));
const requestedSizes = requested.slice(1).filter(value => sizes.some(size => size.name === value));
const selectedStates = requestedStates.length ? requestedStates : states;
const selectedSizes = requestedSizes.length ? sizes.filter(size => requestedSizes.includes(size.name)) : sizes;
const captureRoot = path.join(root, 'captures', label);
const evidenceRoot = path.join(projectRoot, 'build', 'evidence', 'team-prototype-20260912', 'atlas-browser');
const stamp = new Date().toISOString().replace(/[:.]/g, '-');
const profile = path.join(evidenceRoot, `edge-profile-${stamp}`);
const fileUrl = `file:///${path.join(root, 'atlas.html').replace(/\\/g, '/')}`;

function descendants(parentPid) {
  try {
    const query = `$ErrorActionPreference='Stop';$todo=[System.Collections.Generic.Queue[int]]::new();$todo.Enqueue(${parentPid});$result=@();while($todo.Count){$parent=$todo.Dequeue();Get-CimInstance Win32_Process -Filter \"ParentProcessId=$parent\" | ForEach-Object {$result += [pscustomobject]@{pid=$_.ProcessId;parent=$_.ParentProcessId;name=$_.Name};$todo.Enqueue($_.ProcessId)}};$result|ConvertTo-Json -Compress`;
    const raw = execFileSync('powershell.exe', ['-NoProfile','-Command',query], { encoding:'utf8', windowsHide:true }).trim();
    const parsed = raw ? JSON.parse(raw) : [];
    return { known:true, items:(Array.isArray(parsed) ? parsed : [parsed]).filter(item => String(item.name || '').toLowerCase() === 'msedge.exe') };
  } catch (error) { return { known:false, items:[], error:String(error.message || error) }; }
}

function assertSourceAssets() {
  const missing = requiredAssets.filter(relative => !fs.existsSync(path.resolve(root, relative)));
  if (missing.length) throw new Error(`Required concept source assets missing: ${missing.join(', ')}`);
}

async function conceptChecks(page, state, size) {
  const actual = await page.evaluate(async () => {
    const query = selector => document.querySelector(selector);
    const box = selector => { const rect = query(selector).getBoundingClientRect(); return { x:rect.x, y:rect.y, width:rect.width, height:rect.height, right:rect.right, bottom:rect.bottom }; };
    const visible = element => { const style = getComputedStyle(element); const rect = element.getBoundingClientRect(); return style.display !== 'none' && style.visibility !== 'hidden' && rect.width > 0 && rect.height > 0; };
    const physicalFont = selector => { const element = query(selector); if (!element) return 0; const rect = element.getBoundingClientRect(); return Number((parseFloat(getComputedStyle(element).fontSize) * rect.width / Math.max(1, element.offsetWidth)).toFixed(2)); };
    const controls = [...document.querySelectorAll('button,.card')].filter(visible).map(element => { const r = element.getBoundingClientRect(); const top = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2); return { name:element.getAttribute('aria-label') || element.textContent.trim(), width:r.width, height:r.height, inViewport:r.left >= 0 && r.top >= 0 && r.right <= innerWidth && r.bottom <= innerHeight, topmost:top === element || element.contains(top) }; });
    const viewport = query('.viewport').getBoundingClientRect();
    const screen = query('#screen').getBoundingClientRect();
    const backgroundImages = { screen:getComputedStyle(query('#screen')).backgroundImage, card:document.querySelector('.card') ? getComputedStyle(query('.card'),'::before').backgroundImage : '', kit:document.querySelector('.kit-chip') ? getComputedStyle(query('.kit-chip'),'::before').backgroundImage : '', magazine:document.querySelector('.kit-magazine') ? getComputedStyle(query('.kit-magazine')).backgroundImage : '', privateBack:document.querySelector('.rival-back') ? getComputedStyle(query('.rival-back')).backgroundImage : '', sprite:document.querySelector('.figurine .sprite') ? getComputedStyle(query('.figurine .sprite')).backgroundImage : '', printed:document.querySelector('.printer .solid') ? getComputedStyle(query('.printer .solid')).backgroundImage : '' };
    const backgroundLoaded = Object.fromEntries(await Promise.all(Object.entries(backgroundImages).map(async ([key, value]) => {
      const match = value.match(/url\(["']?(.*?)["']?\)/);
      if (!match) return [key, !value];
      const loaded = await new Promise(resolve => { const image = new Image(); image.onload=()=>resolve(image.naturalWidth > 0 && image.naturalHeight > 0); image.onerror=()=>resolve(false); image.src=match[1]; });
      return [key, loaded];
    })));
    const clippedText = [...document.querySelectorAll('.hud,.forecast,.queue-item,.figurine .copy,.card-name,.private-copy,.starter .native,.starter .forge-side-plate,.starter .forge-center,.starter .starter-choose,.starter .starter-inspect-button')].filter(visible).filter(element => {
      const rect = element.getBoundingClientRect();
      const container = element.closest('.enemy-active,.player-active') ? query('#screen') : element.parentElement;
      const bounds = container.getBoundingClientRect();
      return rect.left < bounds.left - 1 || rect.top < bounds.top - 1 || rect.right > bounds.right + 1 || rect.bottom > bounds.bottom + 1;
    }).map(element => element.textContent.trim());
    return {
      nativeTextCount:[...document.querySelectorAll('.native,.card-name,.copy,.queue-item,.action,.kit-chip,.kit-magazine,.receipt-copy,.receipt-copy h2,.receipt-copy p,.grant-caption,.starter .back,.forge-center')].filter(element => visible(element) && element.textContent.trim()).length,
      figures:[...document.querySelectorAll('.figurine')].filter(visible).length, activeCount:[...document.querySelectorAll('.enemy-active,.player-active')].filter(visible).length, reserveCount:[...document.querySelectorAll('.reserve')].filter(visible).length,
      hasFixtureFigures:query('#screen').hasAttribute('data-expected-figures'), fixtureFigures:Number(query('#screen').dataset.expectedFigures || 0),
      cards:[...document.querySelectorAll('.card')].filter(visible).length,
      roster:[...document.querySelectorAll('.roster-card')].filter(visible).length,
      kitCards:[...document.querySelectorAll('.kit-chip')].filter(visible).length,
      controls, viewport, screen,
      safeTop:Number(query('.viewport').dataset.safeTop || 0), safeBottom:Number(query('.viewport').dataset.safeBottom || 0),
      fonts:{ reserve:physicalFont('.reserve .copy'), active:physicalFont('.enemy-active .copy'), hand:physicalFont('.card-name'), action:physicalFont('.action'), primary:physicalFont('.starter-choose,.forge-center'), heading:physicalFont('.title'), queue:physicalFont('.queue-item') },
      activeHolderCount:document.querySelectorAll('.active-bay').length,
      nestedReceiptCount:document.querySelectorAll('.receipt').length,
      resultScreenCount:document.querySelectorAll('.result-screen').length,
      starterPhase:query('#screen').dataset.starterPhase || '',
      starterBlueprints:[...document.querySelectorAll('.starter-blueprint')].filter(visible).length,
      forgeSolid:[...document.querySelectorAll('.forge-solid')].filter(visible).length,
      forgeWire:[...document.querySelectorAll('.forge-wire')].filter(visible).length,
      printedInPrinter:document.querySelectorAll('.printer').length,
      privateBacks:[...document.querySelectorAll('.rival-back')].filter(visible).length,
      backgroundImages, backgroundLoaded, clippedText,
      identities:[...document.querySelectorAll('.figurine,.printer')].filter(visible).map(element => ({ creature:element.dataset.creature, owner:element.dataset.owner }))
    };
  });
  const expected = actual.hasFixtureFigures ? actual.fixtureFigures : expectedFigures[state];
  const boundsPass = actual.screen.x >= -1 && actual.screen.y >= -1 && actual.screen.right <= actual.viewport.right + 1 && actual.screen.bottom <= actual.viewport.bottom + 1;
  const hitPass = actual.controls.every(control => control.width >= 48 && control.height >= 48 && control.inViewport && control.topmost);
  const identityCounts = actual.identities.reduce((result, identity) => { const key = `${identity.owner}:${identity.creature}`; result[key] = (result[key] || 0) + 1; return result; }, {});
  const uniqueIdentities = Object.values(identityCounts).every(value => value === 1);
  const terminalState = ['win-result-m2','loss-result-m2','draw-result-m2'].includes(state);
  const starterState = state.startsWith('starter-');
  const editorState = ['teamvalid','teaminvalid','team-empty','team-one','supportkit','supportkit-excluded'].includes(state);
  const workshopState = ['workshop-prototype-nav','preflight-error','recovery','focus-sheet','reduced-motion'].includes(state);
  const battleState = !editorState && !workshopState && state !== 'guaranteedstarterreceipt' && !terminalState && !starterState;
  const expectedStarterPhase = starterState ? state.slice('starter-'.length) : '';
  const starterBackground = ['starter-choice','starter-inspect'].includes(state) ? actual.backgroundImages.screen.includes('starter-blueprint-desk-v4.png') : actual.backgroundImages.screen.includes('enclosed-forge-static-master-v1.png');
  const backgroundPass = (starterState ? starterBackground : workshopState ? (state === 'recovery' ? actual.backgroundImages.screen.includes('SY-02-recovery-ledger-text-free-v2.png') : ['focus-sheet','reduced-motion','preflight-error'].includes(state) ? actual.backgroundImages.screen.includes('ST-01-settings-instrument-text-free-v3.png') : actual.backgroundImages.screen.includes('workshop-backplate-text-free-v1.png')) : (state === 'guaranteedstarterreceipt' || terminalState) ? actual.backgroundImages.screen.includes('BA-05-result-receipt-v4.png') : editorState ? actual.backgroundImages.screen.includes('TM-R1-team-support-workbench-text-free-v1.png') : actual.backgroundImages.screen.includes('BA-R1-team-autobattle-chassis-text-free-v1.png')) && actual.backgroundLoaded.screen && (actual.cards ? actual.backgroundImages.card.includes('support_cards_') && actual.backgroundLoaded.card : true) && (actual.kitCards ? actual.backgroundImages.kit.includes('support_cards_') && actual.backgroundLoaded.kit : true) && (battleState ? actual.backgroundImages.privateBack.includes('support_card_back_source_v1.png') && actual.backgroundLoaded.privateBack : true) && (terminalState ? actual.nestedReceiptCount === 0 && actual.resultScreenCount === 1 : true) && (actual.figures ? (actual.backgroundImages.sprite.includes('battle_facing') || actual.backgroundImages.sprite.includes('voltwig_sprite_sheet')) && actual.backgroundLoaded.sprite : true) && (actual.printedInPrinter ? (actual.backgroundImages.printed.includes('battle_facing') || actual.backgroundImages.printed.includes('voltwig_sprite_sheet')) && actual.backgroundLoaded.printed : true);
  const starterPass = !starterState || (actual.figures === 0 && actual.cards === 0 && actual.privateBacks === 0 && actual.printedInPrinter === 0 && actual.starterPhase === expectedStarterPhase && (['choice','inspect'].includes(expectedStarterPhase) ? actual.starterBlueprints === 1 && actual.forgeSolid === 0 : expectedStarterPhase === 'voucher' ? actual.starterBlueprints === 0 && actual.forgeSolid === 0 && actual.forgeWire === 0 : ['awaken','rawcomplete'].includes(expectedStarterPhase) ? actual.forgeSolid === 1 && actual.forgeWire === 0 : actual.forgeSolid === 1 && actual.forgeWire === 1));
  const statePass = actual.figures === expected && actual.activeHolderCount === 0 && uniqueIdentities && starterPass && (battleState ? actual.privateBacks === 4 : true) && (terminalState ? actual.cards === 0 && actual.printedInPrinter === 0 && actual.privateBacks === 0 : true) && (state === 'choosefirstprint' ? actual.printedInPrinter === 0 : true) && (['printEarly','print60','rawcomplete','awaken'].includes(state) ? actual.printedInPrinter === 2 : true) && (['activewaiting','activewaitingrun'].includes(state) ? actual.printedInPrinter === 0 : true) && (['finaldefeat','Draw'].includes(state) ? actual.cards === 0 : true);
  const textNodePass = actual.nativeTextCount >= ((state === 'guaranteedstarterreceipt' || workshopState) ? 3 : 4);
  const textPass = textNodePass && (starterState ? actual.fonts.primary >= 15.5 : actual.fonts.action >= 15.5) && (actual.cards ? actual.fonts.hand >= 15.5 : true) && (actual.figures ? (actual.activeCount ? actual.fonts.active >= 15.5 : true) && (actual.reserveCount ? actual.fonts.reserve >= 15.5 : true) : true) && (battleState ? actual.fonts.heading >= 14 && actual.fonts.queue >= 15.5 : true) && Boolean(actual.backgroundImages.privateBack || !battleState);
  const tallPass = size.name !== '720x1600' || (actual.safeTop >= 24 && actual.safeBottom >= 24 && actual.screen.y === actual.safeTop && actual.screen.bottom <= actual.viewport.bottom - actual.safeBottom + 1);
  const clipPass = actual.clippedText.length === 0;
  const pass = boundsPass && hitPass && statePass && textPass && tallPass && backgroundPass && clipPass;
  return { kind:'concept-only DOM source/layout checks; not game or device evidence', state, size:size.name, expectedFigures:expected, boundsPass, hitPass, statePass, textPass, tallPass, backgroundPass, clipPass, identityCounts, pass, ...actual };
}

async function main() {
  assertSourceAssets();
  fs.mkdirSync(captureRoot, { recursive:true });
  fs.mkdirSync(profile, { recursive:true });
  if (!fs.existsSync(edge)) throw new Error(`Missing Edge: ${edge}`);
  let context;
  const ledger = { startedAt:new Date().toISOString(), nodePid:process.pid, executable:edge, captureLabel:label, states:selectedStates, sizes:selectedSizes, userDataDir:profile, sourceAssets:requiredAssets, cleanup:'pending', evidenceScope:'offline native-HTML concept atlas only; not Godot/runtime/device evidence' };
  fs.writeFileSync(path.join(captureRoot, 'render-ledger.json'), JSON.stringify(ledger, null, 2));
  try {
    context = await chromium.launchPersistentContext(profile, { headless:true, executablePath:edge, args:['--disable-gpu','--no-first-run'] });
    ledger.browserTreeAtStart = descendants(process.pid);
    const page = await context.newPage();
    ledger.conceptChecks = [];
    for (const state of selectedStates) for (const size of selectedSizes) {
      await page.setViewportSize({ width:size.width, height:size.height });
      await page.goto(`${fileUrl}?capture=1#${encodeURIComponent(state)}`, { waitUntil:'load' });
      await page.evaluate(nextState => window.setConceptState(nextState), state);
      await page.waitForTimeout(150);
      const result = await conceptChecks(page, state, size);
      ledger.conceptChecks.push(result);
      const suffix = result.pass ? '' : '-DIAGNOSTIC';
      const screenshotPath = path.join(captureRoot, `${state}-${size.name}${suffix}.png`);
      await page.screenshot({ path:screenshotPath, clip:{ x:0, y:0, width:size.width, height:size.height } });
      result.capture = path.relative(projectRoot, screenshotPath).replace(/\\/g, '/');
      if (!result.pass) throw new Error(`Concept layout failed ${state}/${size.name}; diagnostic retained: ${JSON.stringify(result)}`);
    }
  } finally {
    if (context) await context.close();
    await new Promise(resolve => setTimeout(resolve, 300));
    ledger.browserTreeAfterClose = descendants(process.pid);
    ledger.finishedAt = new Date().toISOString();
    const safeProfile = path.relative(evidenceRoot, profile) && !path.relative(evidenceRoot, profile).startsWith('..') && path.resolve(profile) !== path.resolve(evidenceRoot);
    if (safeProfile && ledger.browserTreeAfterClose.known && ledger.browserTreeAfterClose.items.length === 0) {
      fs.rmSync(profile, { recursive:true, force:true });
      ledger.userDataCleanup = 'removed exact task-owned Edge profile after tracked browser descendants exited';
    } else ledger.userDataCleanup = !safeProfile ? 'retained because isolated profile containment could not be proven' : ledger.browserTreeAfterClose.known ? 'retained because tracked Edge descendants remain' : 'retained because child-process inspection is uncertain';
    ledger.cleanup = 'persistent Edge context closed';
    fs.writeFileSync(path.join(captureRoot, 'render-ledger.json'), JSON.stringify(ledger, null, 2));
  }
}
main().catch(error => { console.error(error.stack || error); process.exitCode = 1; });
