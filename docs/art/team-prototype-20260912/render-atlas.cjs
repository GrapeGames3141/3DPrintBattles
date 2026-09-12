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
const states = ['teamvalid','teaminvalid','team-empty','team-one','supportkit','supportkit-excluded','workshop-prototype-nav','preflight-error','recovery','focus-sheet','reduced-motion','preflight-empty','choosefirstprint','printEarly','print60','rawcomplete','awaken','first-entry-active','combined-second-plan','second-print','reserve-1-entry','third-plan-behind-gear','queue-capacity-reject','equipment-auto-fit','equipment-fitted','printing-wait-plan','third-print-awaken','reserve-2-entry','swap-plan','swap-and-attack','swap-result','replacement-risk-plan','replacement-attack','auto-replacement','empty-active-required','last-member-printing','last-member-active','empty-active-replenish','replenish-run','replenish-next-plan','replenish-last-printing','replenish-last-active','hand-exhausted','win-result-m2','loss-result-m2','draw-result-m2','guaranteedstarterreceipt','receipt-aquafin','receipt-voltwig','starter-choice','starter-choice-aquafin','starter-choice-voltwig','starter-inspect','starter-voucher','starter-print-early','starter-print-60','starter-rawcomplete','starter-awaken','HC150-RM'];
const sizes = [{ name:'576x1024', width:576, height:1024 }, { name:'720x1280', width:720, height:1280 }, { name:'720x1600', width:720, height:1600 }];
const expectedFigures = { choosefirstprint:6, populatedPlan:6, selectedsupport:6, printEarly:5, print60:5, rawcomplete:5, awaken:5, reserveentry:6, activewaiting:5, swap:6, attack:6, autoreplacement:6, finaldefeat:6, Draw:6, guaranteedstarterreceipt:0, 'HC150-RM':6 };
const coreExpected = {
  'combined-second-plan':{player:{cinder:'Active',aquafin:'Unspent',mossmunk:'Unspent'},rival:{cinder:'Active',aquafin:'Unspent',mossmunk:'Unspent'},cards:['suit','gem','surge','raw'],backs:4,locked:false,rivalQueue:'EMPTY',gear:false},
  'equipment-auto-fit':{player:{cinder:'Active',aquafin:'Ready',mossmunk:'Queued'},rival:{cinder:'Active',aquafin:'Ready',mossmunk:'Queued'},cards:['gem','surge','raw','heated'],backs:4,locked:true,rivalQueue:'1: Suit · 2: Mossmunk',gear:true},
  'auto-replacement':{player:{cinder:'Active',aquafin:'Defeated',mossmunk:'Ready'},rival:{cinder:'Active',aquafin:'Ready',mossmunk:'Ready'},cards:['gem','raw','heated'],backs:4,locked:true,rivalQueue:'EMPTY',gear:false}
};
const coreCardExpected={raw:{label:'Raw Filament +2',short:'Raw\n+2',aria:'Raw Filament, cost 0, gain 2 filament'},heated:{label:'Heated Spool +3',short:'Heated\n+3',aria:'Heated Spool, cost 0, gain 3 filament'},suit:{label:'Full Suit · 2',short:'Suit\n2',aria:'Full Suit, cost 2, one print-work, auto-fit +8 ablative armor, one armor slot'},gem:{label:'Iron Gem · 2',short:'Gem\n2',aria:'Iron Gem, cost 2, one print-work, auto-fit +2 attack, one gem slot, replaces not stacks'},surge:{label:'Forge Surge · 2',short:'Surge\n2',aria:'Forge Surge, cost 2, this-cycle attack 150% rounded down, consumed even with no hit'}};
const requiredAssets = [
  'BA-R1-team-autobattle-chassis-text-free-v1.png', 'TM-R1-team-support-workbench-text-free-v1.png',
  '../../../assets/cards/support_card_back_source_v1.png', '../../../assets/cards/support_cards_resources_landscape_v2.png', '../../../assets/cards/support_cards_offense_landscape_v2.png', '../../../assets/ui/physical_ui/m3/BA-05-result-receipt-v4.png',
  '../../../assets/ui/physical_ui/forge-continuity/enclosed-forge-static-master-v1.png', '../../../assets/ui/physical_ui/m1-r2/starter-blueprint-desk-v4.png', '../../../assets/ui/physical_ui/forge-continuity/carriage-guide-v1.png', '../../../assets/ui/physical_ui/forge-continuity/carriage-head-v1.png',
  '../../../assets/creatures/2d/battle-facing/cinderpaw_battle_facing_4x2.png', '../../../assets/creatures/2d/battle-facing/aquafin_battle_facing_4x2.png',
  '../../../assets/creatures/2d/battle-facing/mossmunk_battle_facing_4x2.png', '../../../assets/creatures/2d/voltwig_sprite_sheet.png', 'EQ-R1-quadruped-armor-kit-raw-draft-v2.png'
];
const requested = process.argv.slice(2);
const label = requested[0] || 'v1';
if (!/^[a-z0-9][a-z0-9_-]*$/i.test(label)) throw new Error('Unsafe capture label');
const accessibilityMode = 'text150-hc-rm';
const useText150HcRm = requested.slice(1).includes(accessibilityMode);
const unknownArguments = requested.slice(1).filter(value => value !== accessibilityMode && !states.includes(value) && !sizes.some(size => size.name === value));
if (unknownArguments.length) throw new Error(`Unknown atlas state or size: ${unknownArguments.join(', ')}`);
const requestedStates = requested.slice(1).filter(value => states.includes(value));
const requestedSizes = requested.slice(1).filter(value => sizes.some(size => size.name === value));
const selectedStates = requestedStates.length ? requestedStates : states;
const selectedSizes = requestedSizes.length ? sizes.filter(size => requestedSizes.includes(size.name)) : sizes;
const captureQuery = useText150HcRm ? '?capture=1&text=150&contrast=high&motion=reduced' : '?capture=1';
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
    const screenScale = screen.width / 941;
    const stageRect = element => { const r = element.getBoundingClientRect(); return { x:(r.x-screen.x)/screenScale, y:(r.y-screen.y)/screenScale, width:r.width/screenScale, height:r.height/screenScale }; };
    const approximately = (actualValue, wanted) => Math.abs(actualValue-wanted) <= 1.1;
    const exactRect = (element, wanted) => { if (!element) return false; const rect=stageRect(element); return approximately(rect.x,wanted[0]) && approximately(rect.y,wanted[1]) && approximately(rect.width,wanted[2]) && approximately(rect.height,wanted[3]); };
    const teamBayExpected=[[39.20,266.29,279.37,227.08],[331.70,266.29,277.73,227.08],[627.37,266.29,274.46,227.08]];
    const teamMiniExpected=[[122.54,284.23,104.54,140.50],[414.95,284.23,104.54,140.50],[704.72,284.23,104.54,140.50]];
    const kitExpected=[[71.88,1042.50,138.88,248.40],[220.58,1042.50,143.78,248.40],[372.48,1042.50,143.78,248.40],[524.38,1042.50,143.78,248.40]];
    const textOwners=[...document.querySelectorAll('[data-text-owner]')].filter(visible);
    const glyphDiagnostics=textOwners.map(element => { const rect=element.getBoundingClientRect(), parent=element.parentElement.getBoundingClientRect(); return { text:element.textContent.trim(), scrollWidth:element.scrollWidth, clientWidth:element.clientWidth, scrollHeight:element.scrollHeight, clientHeight:element.clientHeight, insideParent:rect.left >= parent.left-1 && rect.top >= parent.top-1 && rect.right <= parent.right+1 && rect.bottom <= parent.bottom+1 }; });
    const paperOwner={x:94,y:528,right:850,bottom:980};
    const folioOwnerPass=[...document.querySelectorAll('.book-heading,.book-order,.book-eligibility,.book-status')].filter(visible).every(element => { const rect=stageRect(element); return rect.x >= paperOwner.x-1 && rect.y >= paperOwner.y-1 && rect.x+rect.width <= paperOwner.right+1 && rect.y+rect.height <= paperOwner.bottom+1; });
    const glyphsFit=folioOwnerPass && glyphDiagnostics.every(item => item.scrollWidth <= item.clientWidth + 1 && item.scrollHeight <= item.clientHeight + 1 && item.insideParent);
    const teamBays=[...document.querySelectorAll('.team-bay')].filter(visible);
    const teamMinis=[...document.querySelectorAll('.team-mini')].filter(visible);
    const kitFaces=[...document.querySelectorAll('[data-kit-face]')].filter(visible);
    const kitTallies=[...document.querySelectorAll('[data-kit-tally]')].filter(visible).map(element=>Number(element.dataset.tallyCount || 0));
    const teamGeometry=teamBays.every((element,index)=>exactRect(element,teamBayExpected[index])) && teamMinis.every((element,index)=>exactRect(element,teamMiniExpected[index]));
    const kitGeometry=kitFaces.every((element,index)=>exactRect(element,kitExpected[index]));
    const systemState=query('#screen').dataset.systemState || '';
    const systemOwners=[...document.querySelectorAll('[data-nav-owner]')].filter(visible);
    const systemOwnerNames=systemOwners.map(element=>element.dataset.navOwner || '');
    const systemExpected={
      'workshop-prototype-nav':{forge:[241.82,906.56,457.43,261.39],team:[91.49,405.15,196.04,313.66],kit:[679.61,405.15,192.77,236.84],battle:[676.34,661.68,218.92,194.41],settings:[294.06,1248.10,352.88,326.74],back:[26.14,35.94,133.96,78.50]},
      'preflight-error':{back:[29.40,32.68,133.96,78.50],context:[444.38,1450.00,403.48,153.56]},
      'focus-sheet':{back:[29.40,32.68,133.96,78.50],context:[444.38,1450.00,403.48,153.56]},
      'reduced-motion':{back:[29.40,32.68,133.96,78.50],dial:[160.13,1447.92,171.54,160.10],context:[444.38,1450.00,403.48,153.56]},
      recovery:{back:[29.40,32.68,133.96,78.50],continue:[156.83,1279.83,287.50,148.73]}
    };
    const expectedSystem=systemExpected[systemState] || {};
    const systemGeometry=Object.entries(expectedSystem).every(([owner,wanted])=>exactRect(query(`[data-nav-owner="${owner}"]`),wanted));
    const systemText=[...document.querySelectorAll('[data-system-text]')].filter(visible);
    const systemTextFits=systemText.every(element=>element.scrollWidth <= element.clientWidth+1 && element.scrollHeight <= element.clientHeight+1) && systemOwners.every(element=>element.scrollWidth <= element.clientWidth+1 && element.scrollHeight <= element.clientHeight+1);
    const active=document.activeElement, activeStyle=active ? getComputedStyle(active) : null;
    const focusProof=Boolean(active && active.dataset.focusProof === 'true' && parseFloat(activeStyle.outlineWidth) >= 3 && activeStyle.outlineColor !== 'rgb(0, 0, 0)');
    const coreState=query('#screen').dataset.coreFixture || '';
    const coreRecords=[...document.querySelectorAll('[data-core-record]')].filter(visible).map(element=>({seat:element.dataset.seat,creature:element.dataset.creature,status:element.dataset.status}));
    const coreRecordMap=Object.fromEntries(coreRecords.map(record=>[`${record.seat}:${record.creature}`,record.status]));
    const coreText=[...document.querySelectorAll('[data-core-text]')].filter(visible);
    const coreTextFits=coreText.every(element=>{const rect=element.getBoundingClientRect(),owner=element.parentElement.getBoundingClientRect();return element.scrollWidth<=element.clientWidth+1 && element.scrollHeight<=element.clientHeight+1 && rect.left>=owner.left-1 && rect.top>=owner.top-1 && rect.right<=owner.right+1 && rect.bottom<=owner.bottom+1;});
    const coreInputs=[...document.querySelectorAll('[data-core-input]')].filter(visible);
    const coreJobs=[...document.querySelectorAll('.core-creature-job')].filter(visible).map(element=>{const rect=element.getBoundingClientRect(), scan=Number.parseFloat(getComputedStyle(element).getPropertyValue('--scan'))/100;return {owner:element.dataset.jobOwner,id:element.dataset.jobCreature,progress:Number(element.dataset.jobProgress),scanY:rect.top+rect.height*scan,solid:Boolean(element.querySelector('[data-job-solid]')),wire:Boolean(element.querySelector('[data-job-wire]'))};});
    const coreGear=[...document.querySelectorAll('.core-printer')].filter(visible);
    const coreGearRects=coreGear.map(element=>stageRect(element));
    const coreGearExpected={rival:[84.95,204.20,156.83,156.83],player:[84.95,1181.00,156.83,156.83]};
    const coreGearGeometry=coreGear.every(element=>exactRect(element,coreGearExpected[element.dataset.gearOwner]));
    const coreShadows=[...document.querySelectorAll('.core-shadow')].filter(visible);
    const coreShadowGeometry=coreShadows.length===2 && exactRect(query('.core-shadow.rival'),[107.87,325.10,111.13,14.70]) && exactRect(query('.core-shadow.player'),[107.87,1302.80,111.13,14.70]);
    const coreQueues=Object.fromEntries([...document.querySelectorAll('[data-core-queue]')].filter(visible).map(element=>[element.dataset.coreQueue,element.textContent.trim()]));
    const coreActiveGeometry=[['.core-active.rival',[369.19,369.66,202.60,270.15]],['.core-active.player',[369.19,699.93,202.60,270.15]]].every(([selector,wanted])=>!query(selector)||exactRect(query(selector),wanted));
    const coreReserveMiniExpected={r1:[399.50,169.30,86.60,115.43],r2:[706.60,169.60,86.60,115.43],p1:[399.50,1130.10,86.60,115.43],p2:[706.60,1129.00,86.60,115.43]};
    const coreReserveMiniGeometry=[...document.querySelectorAll('.core-reserve .core-mini')].filter(visible).every(element=>{const owner=['r1','r2','p1','p2'].find(value=>element.parentElement.classList.contains(value));return Boolean(owner)&&exactRect(element,coreReserveMiniExpected[owner]);});
    const coreCaptionGeometry=[['.core-active-caption.rival',[279.40,655.10,380.70,58.80]],['.core-active-caption.player',[279.40,953.90,380.70,58.80]]].every(([selector,wanted])=>!query(selector)||exactRect(query(selector),wanted));
    const coreGeometry=(coreState ? coreActiveGeometry && coreReserveMiniGeometry && coreCaptionGeometry && exactRect(query('.core-side-ink'),[22.90,539.10,230.40,375.70]) && exactRect(query('.core-queue.rival'),[347.90,346.40,441.10,44.10]) && exactRect(query('.core-queue.player'),[295.70,1290.60,599.60,44.10]) && coreShadowGeometry && (!coreGear.length || coreGearGeometry) : true);
    const accessibilityFlags={text150:query('#screen').dataset.text150 === 'true',highContrast:query('#screen').dataset.highContrast === 'true',reducedMotion:query('#screen').dataset.reducedMotion === 'true'};
    const largeText={title:query('.battle-core .title')?stageRect(query('.battle-core .title')):null,back:query('.battle-core .back')?stageRect(query('.battle-core .back')):null,backLabel:query('.core-back-label')?stageRect(query('.core-back-label')):null,backText:query('.core-back-label')?.textContent.trim()||'',backAria:query('.battle-core .back')?.getAttribute('aria-label')||'',run:query('.core-run')?stageRect(query('.core-run')):null,side:query('.core-side-ink')?stageRect(query('.core-side-ink')):null,private:query('.core-private')?stageRect(query('.core-private')):null,activeRival:query('.core-active-caption.rival')?stageRect(query('.core-active-caption.rival')):null,activePlayer:query('.core-active-caption.player')?stageRect(query('.core-active-caption.player')):null,queueRival:query('.core-queue.rival')?stageRect(query('.core-queue.rival')):null,queuePlayer:query('.core-queue.player')?stageRect(query('.core-queue.player')):null,readyLabels:[...document.querySelectorAll('.core-label')].filter(visible).map(element=>({text:element.innerText.trim(),rect:stageRect(element),owner:element.parentElement.className})),readyMinis:[...document.querySelectorAll('.core-reserve .core-mini')].filter(visible).map(element=>({id:element.dataset.coreMini,rect:stageRect(element),owner:element.parentElement.className})),dockets:[...document.querySelectorAll('.core-docket-label')].filter(visible).map(element=>({text:element.innerText.trim(),rect:stageRect(element),aria:element.parentElement.getAttribute('aria-label')||'',owner:element.parentElement.className})),tokens:[...document.querySelectorAll('.core-token')].filter(visible).map(element=>({text:element.innerText.trim(),rect:stageRect(element),parent:stageRect(element.parentElement)})),titleText:query('.battle-core .title')?.innerText.trim()||'',titleAria:query('.battle-core .title')?.getAttribute('aria-label')||'',sideText:query('.core-side-ink')?.innerText.trim()||'',privateText:query('.core-private')?.innerText.trim()||'',privateAria:query('.core-private')?.getAttribute('aria-label')||'',activeText:[...document.querySelectorAll('.core-active-caption')].filter(visible).map(element=>element.innerText.trim()),queueAria:[...document.querySelectorAll('.core-queue')].filter(visible).map(element=>element.getAttribute('aria-label')||''),fonts:{title:physicalFont('.battle-core .title'),back:physicalFont('.battle-core .back'),backLabel:physicalFont('.core-back-label'),run:physicalFont('.core-run'),side:physicalFont('.core-side-ink'),private:physicalFont('.core-private'),active:physicalFont('.core-active-caption'),ready:physicalFont('.core-label'),docket:physicalFont('.core-docket-label'),token:physicalFont('.core-token'),queue:physicalFont('.core-queue'),card:physicalFont('.core-card .card-name')},cardLabels:[...document.querySelectorAll('.core-card')].filter(visible).map(element=>element.dataset.visibleLabel||'')};
    const print60Markers=[...document.querySelectorAll('[data-core-job-marker]')].filter(visible).map(element=>{const rect=stageRect(element), parent=element.parentElement.getBoundingClientRect(), own=element.getBoundingClientRect();return {seat:element.parentElement.dataset.seat||'',text:element.textContent.trim(),aria:element.parentElement.getAttribute('aria-label')||'',rect,scrollWidth:element.scrollWidth,clientWidth:element.clientWidth,scrollHeight:element.scrollHeight,clientHeight:element.clientHeight,fits:element.scrollWidth<=element.clientWidth+1&&element.scrollHeight<=element.clientHeight+1,inside:own.left>=parent.left-1&&own.top>=parent.top-1&&own.right<=parent.right+1&&own.bottom<=parent.bottom+1};});
    const print60RunLabel=query('.core-run-label')?(()=>{const element=query('.core-run-label'),rect=stageRect(element),parent=element.parentElement.getBoundingClientRect(),own=element.getBoundingClientRect();return {text:element.innerText.trim(),aria:element.parentElement.getAttribute('aria-label')||'',rect,font:physicalFont('.core-run-label'),scrollWidth:element.scrollWidth,clientWidth:element.clientWidth,scrollHeight:element.scrollHeight,clientHeight:element.clientHeight,fits:element.scrollWidth<=element.clientWidth+1&&element.scrollHeight<=element.clientHeight+1,inside:own.left>=parent.left-1&&own.top>=parent.top-1&&own.right<=parent.right+1&&own.bottom<=parent.bottom+1};})():null;
    return {
      nativeTextCount:[...document.querySelectorAll('.native,.card-name,.copy,.queue-item,.action,.kit-chip,.kit-magazine,.receipt-copy,.receipt-copy h2,.receipt-copy p,.grant-caption,.starter .back,.forge-center,.system-button,.settings-dial,.core-active-caption,.core-queue,.core-side-ink,.core-label,.core-token')].filter(element => visible(element) && element.textContent.trim()).length, starterChoice:query('#screen').dataset.starterChoice||'', starterGrant:query('#screen').dataset.starterGrant||'', receiptCta:query('.receipt-screen .action')?{text:query('.receipt-screen .action').innerText.trim(),aria:query('.receipt-screen .action').getAttribute('aria-label')||'',route:query('.receipt-screen .action').dataset.routeOwner||''}:null, grants:[...document.querySelectorAll('.grant-card')].filter(visible).map(element=>({id:element.dataset.creature,caption:element.textContent.trim(),width:element.getBoundingClientRect().width,height:element.getBoundingClientRect().height,font:parseFloat(getComputedStyle(element.querySelector('.grant-caption')).fontSize)*screenScale})),
      figures:[...document.querySelectorAll('.figurine')].filter(visible).length, activeCount:[...document.querySelectorAll('.enemy-active,.player-active')].filter(visible).length, reserveCount:[...document.querySelectorAll('.reserve')].filter(visible).length,
      hasFixtureFigures:query('#screen').hasAttribute('data-expected-figures'), fixtureFigures:Number(query('#screen').dataset.expectedFigures || 0),
      cards:[...document.querySelectorAll('.card')].filter(visible).length,
      roster:[...document.querySelectorAll('.roster-card')].filter(visible).length,
      kitCards:[...document.querySelectorAll('.kit-chip')].filter(visible).length,
      teamArt:teamMinis.length, teamCreatures:teamBays.map(element=>element.dataset.creature || ''), duplicateMarked:Boolean(query('.team-bay.invalid')),
      teamGeometry, kitFaces:kitFaces.length, kitCounts:kitFaces.map(element=>Number(element.dataset.kitCount || 0)), kitTallies, kitGeometry, folioText:query('.book-order') ? query('.book-order').textContent : '', glyphsFit, folioOwnerPass, glyphDiagnostics,
      systemState, systemOwnerNames, systemGeometry, systemTextFits, systemTextValues:systemText.map(element=>element.textContent.trim()), systemTextDiagnostics:[...systemText,...systemOwners].map(element=>({name:element.dataset.navOwner || element.className,scrollWidth:element.scrollWidth,clientWidth:element.clientWidth,scrollHeight:element.scrollHeight,clientHeight:element.clientHeight})), focusProof, focusedOwner:active?.dataset?.navOwner || '', genericWorkshopActions:[...document.querySelectorAll('.workshop .action')].filter(visible).length, disabledSystemOwners:systemOwners.filter(element=>element.disabled).map(element=>element.dataset.navOwner || ''), reducedMotionChecked:query('.settings-dial')?.getAttribute('aria-checked') || '', coreState, coreRecords, coreRecordMap, coreSeatActiveCounts:Object.fromEntries(['rival','player'].map(seat=>[seat,coreRecords.filter(record=>record.seat===seat && record.status==='Active').length])), coreReserveOwners:[...document.querySelectorAll('.core-reserve')].filter(visible).map(element=>['r1','r2','p1','p2'].find(owner=>element.classList.contains(owner)) || ''), coreTextFits, coreTextDiagnostics:coreText.map(element=>({text:element.textContent.trim(),scrollWidth:element.scrollWidth,clientWidth:element.clientWidth,scrollHeight:element.scrollHeight,clientHeight:element.clientHeight})), coreInputs:coreInputs.map(element=>{const style=getComputedStyle(element);return {kind:element.dataset.coreInput,id:element.dataset.coreCard || '',seat:element.dataset.seat || 'player',creature:element.dataset.creature || '',pressed:element.getAttribute('aria-pressed') || 'false',outlineWidth:parseFloat(style.outlineWidth),outlineColor:style.outlineColor,disabled:element.disabled,aria:element.getAttribute('aria-label')||''};}), coreJobs, coreHand:[...document.querySelectorAll('.core-card')].filter(visible).length, coreCards:[...document.querySelectorAll('.core-card')].filter(visible).map(element=>({id:element.dataset.coreCard,label:element.textContent.trim(),aria:element.getAttribute('aria-label') || '',pressed:element.getAttribute('aria-pressed'),disabled:element.disabled})), coreGear:coreGear.map(element=>({job:element.dataset.jobType,target:element.dataset.lockedTarget,owner:element.dataset.gearOwner,filter:getComputedStyle(element.querySelector('.core-gear')).filter})), coreGearGeometry, coreQueues, coreGeometry, accessibilityFlags, largeText, duplicateStatusRows:document.querySelectorAll('.status-records').length, coreThirdBay:document.querySelectorAll('.core-reserve.r3,.core-reserve.p3').length,
      controls, viewport, screen, print60Markers, print60RunLabel,
      screenInViewportTop:screen.y-viewport.y, screenInViewportBottom:viewport.bottom-screen.bottom,
      safeTop:Number(query('.viewport').dataset.safeTop || 0), safeBottom:Number(query('.viewport').dataset.safeBottom || 0),
      fonts:{ reserve:physicalFont('.reserve .copy'), active:physicalFont('.enemy-active .copy'), hand:physicalFont('.card-name'), action:physicalFont('.action'), primary:physicalFont('.starter-choose,.forge-center'), heading:physicalFont('.title'), queue:physicalFont('.queue-item'), editorOrder:physicalFont('.book-order'), editorEligibility:physicalFont('.book-eligibility'), editorStatus:physicalFont('.book-status'), teamCaption:physicalFont('.team-caption'), kitName:physicalFont('.kit-name'), kitCount:physicalFont('.kit-chip em'), systemButton:physicalFont('.system-button'), settingsHeader:physicalFont('.settings-header'), settingsBody:physicalFont('.settings-body'), settingsDial:physicalFont('.settings-dial'), recoveryMessage:physicalFont('.recovery-message'), coreActive:physicalFont('.core-active-caption'), coreReserve:physicalFont('.core-label,.core-token,.core-status'), coreHand:physicalFont('.core-card .card-name'), coreSide:physicalFont('.core-side-ink'), corePrivate:physicalFont('.core-private') },
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
  const starterReceiptState = ['guaranteedstarterreceipt','receipt-aquafin','receipt-voltwig'].includes(state);
  const terminalState = ['win-result-m2','loss-result-m2','draw-result-m2'].includes(state);
  const starterState = state.startsWith('starter-');
  const editorState = ['teamvalid','teaminvalid','team-empty','team-one','supportkit','supportkit-excluded'].includes(state);
  const workshopState = ['workshop-prototype-nav','preflight-error','recovery','focus-sheet','reduced-motion'].includes(state);
  const battleState = !editorState && !workshopState && !starterReceiptState && !terminalState && !starterState;
  const expectedStarterPhase = starterState ? (state.startsWith('starter-choice-') ? 'choice' : state.slice('starter-'.length)) : '';
  const starterBackground = (state.startsWith('starter-choice') || state === 'starter-inspect') ? actual.backgroundImages.screen.includes('starter-blueprint-desk-v4.png') : actual.backgroundImages.screen.includes('enclosed-forge-static-master-v1.png');
  const backgroundPass = (starterState ? starterBackground : workshopState ? (state === 'recovery' ? actual.backgroundImages.screen.includes('SY-02-recovery-ledger-text-free-v2.png') : ['focus-sheet','reduced-motion','preflight-error'].includes(state) ? actual.backgroundImages.screen.includes('ST-01-settings-instrument-text-free-v3.png') : actual.backgroundImages.screen.includes('workshop-backplate-text-free-v1.png')) : (starterReceiptState || terminalState) ? actual.backgroundImages.screen.includes('BA-05-result-receipt-v4.png') : editorState ? actual.backgroundImages.screen.includes('TM-R1-team-support-workbench-text-free-v1.png') : actual.backgroundImages.screen.includes('BA-R1-team-autobattle-chassis-text-free-v1.png')) && actual.backgroundLoaded.screen && (actual.cards ? actual.backgroundImages.card.includes('support_cards_') && actual.backgroundLoaded.card : true) && (actual.kitCards ? actual.backgroundImages.kit.includes('support_cards_') && actual.backgroundLoaded.kit : true) && (battleState ? actual.backgroundImages.privateBack.includes('support_card_back_source_v1.png') && actual.backgroundLoaded.privateBack : true) && (terminalState ? actual.nestedReceiptCount === 0 && actual.resultScreenCount === 1 : true);
  const starterPass = !starterState || (actual.figures === 0 && actual.cards === 0 && actual.privateBacks === 0 && actual.printedInPrinter === 0 && actual.starterPhase === expectedStarterPhase && (['choice','inspect'].includes(expectedStarterPhase) ? actual.starterBlueprints === 1 && actual.forgeSolid === 0 : expectedStarterPhase === 'voucher' ? actual.starterBlueprints === 0 && actual.forgeSolid === 0 && actual.forgeWire === 0 : ['awaken','rawcomplete'].includes(expectedStarterPhase) ? actual.forgeSolid === 1 && actual.forgeWire === 0 : actual.forgeSolid === 1 && actual.forgeWire === 1));
  const teamExpectedArtwork={ 'team-empty':0, 'team-one':1, teaminvalid:3, teamvalid:3, supportkit:3, 'supportkit-excluded':3 };
  const teamEditorPass = !Object.hasOwn(teamExpectedArtwork,state) || (actual.teamArt === teamExpectedArtwork[state] && actual.teamGeometry && (state !== 'teamvalid' || new Set(actual.teamCreatures).size === 3 && actual.teamCreatures.every(Boolean)) && (state !== 'teaminvalid' || actual.duplicateMarked && actual.teamCreatures.filter(id=>id === 'cinder').length === 2));
  const kitEditorPass = !editorState || (actual.kitFaces === 4 && actual.kitGeometry && actual.kitCounts.length === 4 && (!state.startsWith('supportkit') || (state==='supportkit-excluded' ? actual.kitTallies.join('|')==='2|2|3|3|4|1' && actual.kitCounts[0]===2 && actual.folioText.includes('Legacy Trap ×1') : actual.kitTallies.length === 5 && actual.kitTallies.reduce((sum,value)=>sum+value,0) === 15 && actual.folioText.includes('Heated Spool ×2'))));
  const systemExpectedOwners={ 'workshop-prototype-nav':['forge','team','kit','battle','settings','back'], 'preflight-error':['back','context'], 'focus-sheet':['back','context'], 'reduced-motion':['back','dial','context'], recovery:['back','continue'] };
  const systemPass = !workshopState || (actual.systemGeometry && actual.systemTextFits && actual.genericWorkshopActions === 0 && actual.disabledSystemOwners.length === 0 && actual.systemOwnerNames.join('|') === systemExpectedOwners[state].join('|') && (state !== 'focus-sheet' || actual.focusProof && actual.focusedOwner === 'context') && (state !== 'reduced-motion' || actual.reducedMotionChecked === 'true') && (state !== 'recovery' || actual.systemTextValues.join(' ').replace(/\.No/g,'. No').includes('Recovered Team and Kit preview. No legacy save mutation.')));
  const coreFixture = coreExpected[state];
  const isCoreFixture = Boolean(actual.coreState);
  const expectedCoreRecords = coreFixture ? Object.fromEntries(Object.entries(coreFixture).filter(([key])=>key==='player'||key==='rival').flatMap(([seat,records])=>Object.entries(records).map(([creature,status])=>[`${seat}:${creature}`,status]))) : {};
  const coreStatusPass = !coreFixture || (actual.coreRecords.length === 6 && Object.keys(actual.coreRecordMap).length === 6 && Object.entries(expectedCoreRecords).every(([key,status])=>actual.coreRecordMap[key] === status));
  const coreCardPass = !coreFixture || (actual.coreHand === coreFixture.cards.length && actual.coreCards.length === coreFixture.cards.length && actual.coreCards.every((card,index)=>card.id === coreFixture.cards[index] && card.label === (actual.accessibilityFlags.text150 ? coreCardExpected[card.id].short.replace('\n','') : coreCardExpected[card.id].label) && card.aria.startsWith(coreCardExpected[card.id].aria)) && actual.coreCards.filter(card=>card.id === 'raw' || card.id === 'heated').every(card=>card.label === (actual.accessibilityFlags.text150 ? coreCardExpected[card.id].short.replace('\n','') : coreCardExpected[card.id].label) && card.aria.startsWith(coreCardExpected[card.id].aria)));
  const rectPass=(actualRect, expectedRect)=>Boolean(actualRect) && expectedRect.every((value,index)=>Math.abs([actualRect.x,actualRect.y,actualRect.width,actualRect.height][index]-value)<=1.1);
  const largeBaseExpected={title:[279.36,44.11,382.28,55.55],back:[26.14,20,133.96,78.50],backLabel:[26.14,20,71.87,78.50],run:[748,1363,174,242],side:[22.87,539.10,230.35,375.70],private:[22.87,359.41,230.35,49.01]};
  const largeStateExpected={
    'combined-second-plan':{title:'6 → 1 · Next 3',phase:'CYCLE 2 · PLAN',filament:'FILAMENT 6 → 1 · NEXT 3',side:'Cycle 2\nPlan\n6−3−2=1\nNext 3\nAquafin\n+ Suit\nEquip\nCinderpaw',private:'Rival ×4',active:'Cinderpaw\nActive · 27 HP|Cinderpaw\nActive · 27 HP',queues:'Rival queue: EMPTY|Player queue: 1: Aquafin · 2: Suit',cards:['Suit\n2','Gem\n2','Surge\n2','Raw\n+2'],cardIds:['suit','gem','surge','raw'],tokenCount:4,queueGeometry:{queueRival:[347.97,343.07,441.09,49.01],queuePlayer:[295.70,1287.34,599.56,49.01]},activeGeometry:{activeRival:[300.60,637.14,339.81,91.49],activePlayer:[300.60,931.20,339.81,91.49]}},
    'swap-plan':{title:'4 · Next 6',phase:'CYCLE 5 · PLAN',filament:'FILAMENT 4 · NEXT 6',side:'Cycle 5\nPlan\nFilament 4\nNext 6\nSwap\nCinderpaw\nwith\nAquafin',private:'Rival ×4',active:'Cinderpaw\nActive · 12 HP|Cinderpaw\nActive · 12 HP',queues:'Rival queue: EMPTY|Player queue: EMPTY',cards:['Gem\n2','Surge\n2','Raw\n+2','Heated\n+3'],cardIds:['gem','surge','raw','heated'],tokenCount:0,queueGeometry:{queueRival:[347.90,346.40,441.10,49.01],queuePlayer:[295.70,1293.88,599.56,49.01]},activeGeometry:{activeRival:[300.60,637.14,339.81,91.49],activePlayer:[300.60,931.20,339.81,91.49]}},
    print60:{title:'4 · Next 6',phase:'CYCLE 1 · RUN',filament:'POST 4 · NEXT 6',side:'Cycle 1\nRun\nPrinting\nCinderpaw\n60%\nPost 4\nNext 6',private:'Rival ×3',active:'',queues:'Rival queue: 1: Cinderpaw|Player queue: 1: Cinderpaw',cards:['Suit\n2','Gem\n2','Surge\n2'],cardIds:['suit','gem','surge'],tokenCount:4,queueGeometry:{queueRival:[347.97,343.07,441.09,49.01],queuePlayer:[295.70,1287.34,599.56,49.01]},activeGeometry:{}}
  };
  const text150Requested=useText150HcRm || state === 'HC150-RM';
  const text150MinFont=size.width === 576 ? 23.8 : 29.8;
  const largeExpected=largeStateExpected[state === 'HC150-RM' ? 'combined-second-plan' : state];
  const largeTokenPass=expectedCount=>actual.largeText.tokens.length === expectedCount && actual.largeText.tokens.every(token=>Math.abs(token.rect.width-277.73)<=1.1 && Math.abs(token.rect.height-91.49)<=1.1 && token.rect.x>=token.parent.x-1 && token.rect.y>=token.parent.y-1 && token.rect.x+token.rect.width<=token.parent.x+token.parent.width+1 && token.rect.y+token.rect.height<=token.parent.y+token.parent.height+1);
  const readyExpected={labels:[[303.90,254.85,277.73,91.49],[611.00,254.85,277.73,91.49],[303.90,1202.39,277.73,91.49],[611.00,1202.39,277.73,91.49]],minis:[[412.17,175.36,61.26,81.68],[719.27,175.52,61.26,81.68],[412.17,1133.59,61.26,81.68],[719.27,1132.79,61.26,81.68]],texts:['Aquafin\nReady 36HP','Mossmunk\nReady 31HP','Aquafin\nReady 36HP','Mossmunk\nReady 31HP']};
  const readyPass=state !== 'swap-plan' || (actual.largeText.readyLabels.length === 4 && actual.largeText.readyMinis.length === 4 && actual.largeText.readyLabels.every((entry,index)=>entry.text === readyExpected.texts[index] && rectPass(entry.rect,readyExpected.labels[index])) && actual.largeText.readyMinis.every((entry,index)=>rectPass(entry.rect,readyExpected.minis[index])));
  const print60MarkerExpected=[{seat:'rival',rect:[111.09,65.35,91.49,49.01]},{seat:'player',rect:[93.12,1058.63,91.49,49.01]}];
  const docketPass=state !== 'print60' || (actual.print60Markers.length === 2 && actual.print60Markers.every((entry,index)=>entry.seat===print60MarkerExpected[index].seat && entry.text==='1' && entry.aria==='Cinderpaw Printing, 60% complete' && entry.fits && entry.inside && rectPass(entry.rect,print60MarkerExpected[index].rect)));
  const print60RunExpected=[767.83,1444.17,137.23,91.49];
  const print60RunPass=state !== 'print60' || Boolean(actual.print60RunLabel) && actual.print60RunLabel.text==='RUN\nWAIT' && actual.print60RunLabel.aria==='Run Cycle unavailable: locked during resolution' && actual.print60RunLabel.font>=text150MinFont && actual.print60RunLabel.fits && actual.print60RunLabel.inside && rectPass(actual.print60RunLabel.rect,print60RunExpected);
  const largeTextPass=!text150Requested || Boolean(largeExpected) && actual.accessibilityFlags.text150 && actual.accessibilityFlags.highContrast && actual.accessibilityFlags.reducedMotion && Object.entries(largeBaseExpected).every(([key,expectedRect])=>rectPass(actual.largeText[key],expectedRect)) && Object.entries(largeExpected.queueGeometry).every(([key,expectedRect])=>rectPass(actual.largeText[key],expectedRect)) && Object.entries(largeExpected.activeGeometry).every(([key,expectedRect])=>rectPass(actual.largeText[key],expectedRect)) && largeTokenPass(largeExpected.tokenCount) && readyPass && docketPass && print60RunPass && actual.largeText.titleText === largeExpected.title && actual.largeText.titleAria.includes(largeExpected.phase) && actual.largeText.titleAria.includes(largeExpected.filament) && actual.largeText.privateText === largeExpected.private && actual.largeText.privateAria === `Rival private hand: ${largeExpected.private.slice(-1)} concealed Support cards` && actual.largeText.sideText === largeExpected.side && actual.largeText.activeText.join('|') === largeExpected.active && actual.largeText.queueAria.join('|') === largeExpected.queues && actual.largeText.cardLabels.join('|') === largeExpected.cards.join('|') && actual.coreCards.length === largeExpected.cardIds.length && actual.coreCards.every((card,index)=>card.id===largeExpected.cardIds[index] && card.aria.startsWith(coreCardExpected[card.id].aria)) && Object.values(actual.largeText.fonts).filter(value=>value>0).every(value=>value>=text150MinFont);
  const coreBackPass=!isCoreFixture || rectPass(actual.largeText.back,largeBaseExpected.back) && rectPass(actual.largeText.backLabel,largeBaseExpected.backLabel) && actual.largeText.backText === '←' && actual.largeText.backAria === 'Back to Workshop' && actual.largeText.fonts.backLabel >= (actual.accessibilityFlags.text150 ? text150MinFont : 15.5);
  const coreRunPass=!isCoreFixture || rectPass(actual.largeText.run,largeBaseExpected.run) && actual.largeText.fonts.run >= (actual.accessibilityFlags.text150 ? text150MinFont : 15.5);
  const coreRenderedGeometry=actual.accessibilityFlags.text150 ? largeTextPass : actual.coreGeometry;
  const coreRenderedText=actual.coreTextFits;
  const coreInputPass = !coreFixture || (coreCardPass && actual.privateBacks === coreFixture.backs && actual.coreInputs.length >= coreFixture.cards.length + 1 && actual.coreInputs.every(input=>['run','hand','reserve','fabrication'].includes(input.kind)) && actual.coreInputs.filter(input=>input.kind!=='fabrication').every(input=>input.disabled === coreFixture.locked));
  const coreGearPass = !coreFixture || (coreFixture.gear ? actual.coreGear.length === 2 && actual.coreGear.every(gear=>gear.job === 'equipment' && gear.target === 'cinder' && gear.filter.includes('gear-alpha-mask')) && actual.coreGearGeometry : actual.coreGear.length === 0);
  const inputFor=(kind,creature='')=>actual.coreInputs.find(input=>input.kind===kind && (!creature || input.creature===creature));
  const hands=actual.coreInputs.filter(input=>input.kind==='hand');
  const maintenanceAssertions={
    'combined-second-plan':()=>inputFor('fabrication','aquafin')?.pressed==='true' && actual.coreCards.find(card=>card.id==='suit')?.pressed==='true',
    'queue-capacity-reject':()=>inputFor('run')?.disabled===true && hands.length===4 && hands.every(input=>!input.disabled),
    'empty-active-replenish':()=>inputFor('fabrication','mossmunk')?.disabled===true && hands.every(input=>input.disabled) && inputFor('run')?.disabled===false,
    'replenish-next-plan':()=>inputFor('fabrication','mossmunk')?.pressed==='true' && inputFor('fabrication','mossmunk')?.disabled===false && hands.every(input=>input.disabled) && inputFor('run')?.disabled===false,
    'swap-plan':()=>inputFor('reserve','aquafin')?.pressed==='true' && actual.coreInputs.filter(input=>input.kind==='reserve').length===2 && actual.coreInputs.filter(input=>input.kind==='reserve').every(input=>!input.disabled) && hands.every(input=>input.disabled),
    'equipment-auto-fit':()=>actual.coreInputs.every(input=>input.disabled),
    'preflight-empty':()=>actual.coreInputs.filter(input=>input.kind==='fabrication').length===3 && actual.coreInputs.filter(input=>input.kind==='fabrication').every(input=>!input.disabled&&input.pressed==='false') && hands.every(input=>!input.disabled) && inputFor('run')?.disabled===true
  };
  const pressedOutlinePass = actual.coreInputs.filter(input=>input.pressed==='true' && (input.kind==='reserve'||input.kind==='fabrication')).every(input=>input.outlineWidth >= 3 && input.outlineColor === 'rgb(139, 246, 255)');
  const maintenanceInputPass = !maintenanceAssertions[state] || (maintenanceAssertions[state]() && actual.coreInputs.filter(input=>input.seat==='rival').length===0 && pressedOutlinePass);
  const genericCorePass = !isCoreFixture || (actual.coreRecords.length === 6 && Object.keys(actual.coreRecordMap).length === 6 && actual.duplicateStatusRows === 0 && actual.coreThirdBay === 0 && actual.coreReserveOwners.every(owner => owner === 'r1' || owner === 'r2' || owner === 'p1' || owner === 'p2') && actual.coreSeatActiveCounts.rival <= 1 && actual.coreSeatActiveCounts.player <= 1 && actual.coreInputs.every(input=>['run','hand','reserve','fabrication'].includes(input.kind)) && coreRenderedText && coreRenderedGeometry && coreBackPass && coreRunPass && maintenanceInputPass);
  const coreBattlePass = (!coreFixture ? genericCorePass : (actual.coreState === state && coreStatusPass && coreInputPass && actual.duplicateStatusRows === 0 && actual.coreThirdBay === 0 && actual.coreQueues.rival === coreFixture.rivalQueue && coreRenderedGeometry && coreRenderedText && coreBackPass && coreRunPass && coreGearPass)) && maintenanceInputPass;
  const starterChoiceExpected={'starter-choice':'cinder','starter-choice-aquafin':'aquafin','starter-choice-voltwig':'voltwig','starter-inspect':'voltwig'};
  const grantExpected={guaranteedstarterreceipt:['cinder','aquafin','mossmunk'],'receipt-aquafin':['aquafin','voltwig','mossmunk'],'receipt-voltwig':['voltwig','cinder','mossmunk']};
  const choiceMapPass=!Object.hasOwn(starterChoiceExpected,state) || actual.starterChoice===starterChoiceExpected[state];
  const grantMapPass=!Object.hasOwn(grantExpected,state) || (actual.grants.length===3 && actual.grants.map(grant=>grant.id).join('|')===grantExpected[state].join('|') && new Set(actual.grants.map(grant=>grant.id)).size===3 && actual.grants.every(grant=>grant.width>=48&&grant.height>=48&&grant.font>=15.5));
  const receiptCtaPass=!starterReceiptState || Boolean(actual.receiptCta) && actual.receiptCta.text === 'CONTINUE\nTO TEAM' && actual.receiptCta.aria === 'Continue to Team' && actual.receiptCta.route === 'team';
  const statePass = actual.figures === expected && actual.activeHolderCount === 0 && uniqueIdentities && starterPass && choiceMapPass && grantMapPass && receiptCtaPass && teamEditorPass && kitEditorPass && systemPass && coreBattlePass && largeTextPass && (battleState && !actual.coreState ? actual.privateBacks === 4 : true) && (terminalState ? actual.cards === 0 && actual.printedInPrinter === 0 && actual.privateBacks === 0 : true) && (state === 'choosefirstprint' && !isCoreFixture ? actual.printedInPrinter === 0 : true) && (['printEarly','print60','rawcomplete','awaken'].includes(state) && !isCoreFixture ? actual.printedInPrinter === 2 : true) && (['activewaiting','activewaitingrun'].includes(state) && !isCoreFixture ? actual.printedInPrinter === 0 : true) && (['finaldefeat','Draw'].includes(state) && !isCoreFixture ? actual.cards === 0 : true);
  const textNodePass = actual.nativeTextCount >= ((state === 'guaranteedstarterreceipt' || workshopState) ? 3 : 4);
  const editorFontPass = !editorState || [actual.fonts.editorOrder,actual.fonts.editorEligibility,actual.fonts.editorStatus,actual.fonts.teamCaption,actual.fonts.kitName,actual.fonts.kitCount].every(value => value >= 15.5);
  const systemFontValues = state === 'workshop-prototype-nav' ? [actual.fonts.systemButton] : state === 'recovery' ? [actual.fonts.systemButton,actual.fonts.recoveryMessage] : [actual.fonts.systemButton,actual.fonts.settingsHeader,actual.fonts.settingsBody,state === 'reduced-motion' ? actual.fonts.settingsDial : 16];
  const systemFontPass = !workshopState || systemFontValues.every(value => value >= 15.5);
  const primaryFontPass = workshopState || isCoreFixture ? true : starterState ? actual.fonts.primary >= 15.5 : actual.fonts.action >= 15.5;
  const coreFontPass = !isCoreFixture || [actual.fonts.heading,actual.fonts.coreReserve,actual.fonts.coreSide,actual.fonts.corePrivate].every(value=>value >= 15.5) && (!actual.coreHand || actual.fonts.coreHand >= 15.5) && (!actual.coreSeatActiveCounts.rival && !actual.coreSeatActiveCounts.player || actual.fonts.coreActive >= 15.5);
  const textPass = textNodePass && editorFontPass && systemFontPass && primaryFontPass && coreFontPass && (actual.cards ? actual.fonts.hand >= 15.5 : true) && (actual.figures ? (actual.activeCount ? actual.fonts.active >= 15.5 : true) && (actual.reserveCount ? actual.fonts.reserve >= 15.5 : true) : true) && (battleState && !actual.coreState ? actual.fonts.heading >= 14 && actual.fonts.queue >= 15.5 : true) && Boolean(actual.backgroundImages.privateBack || !battleState);
  const tallPass = size.name !== '720x1600' || (actual.safeTop >= 24 && actual.safeBottom >= 24 && Math.abs(actual.screen.height / actual.screen.width - 1672 / 941) <= .001 && Math.abs(actual.screenInViewportTop - actual.safeTop) <= 1 && actual.screenInViewportBottom >= actual.safeBottom - 1);
  const clipPass = actual.clippedText.length === 0 && actual.glyphsFit;
  const pass = boundsPass && hitPass && statePass && textPass && tallPass && backgroundPass && clipPass;
  return { kind:'concept-only DOM source/layout checks; not game or device evidence', state, size:size.name, expectedFigures:expected, boundsPass, hitPass, statePass, textPass, tallPass, backgroundPass, clipPass, largeTextPass, identityCounts, pass, ...actual };
}

async function main() {
  assertSourceAssets();
  fs.mkdirSync(captureRoot, { recursive:true });
  fs.mkdirSync(profile, { recursive:true });
  if (!fs.existsSync(edge)) throw new Error(`Missing Edge: ${edge}`);
  let context;
  const ledger = { startedAt:new Date().toISOString(), nodePid:process.pid, executable:edge, captureLabel:label, states:selectedStates, sizes:selectedSizes, requestedAccessibility:useText150HcRm ? {text:'150',contrast:'high',motion:'reduced'} : {text:'100',contrast:'normal',motion:'normal'}, userDataDir:profile, sourceAssets:requiredAssets, cleanup:'pending', evidenceScope:'offline native-HTML concept atlas only; not Godot/runtime/device evidence' };
  fs.writeFileSync(path.join(captureRoot, 'render-ledger.json'), JSON.stringify(ledger, null, 2));
  try {
    context = await chromium.launchPersistentContext(profile, { headless:true, executablePath:edge, args:['--disable-gpu','--no-first-run'] });
    ledger.browserTreeAtStart = descendants(process.pid);
    const page = await context.newPage();
    ledger.conceptChecks = [];
    for (const state of selectedStates) for (const size of selectedSizes) {
      await page.setViewportSize({ width:size.width, height:size.height });
      await page.goto(`${fileUrl}${captureQuery}#${encodeURIComponent(state)}`, { waitUntil:'load' });
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
