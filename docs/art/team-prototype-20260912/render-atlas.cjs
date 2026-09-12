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
const expectedFigures = { choosefirstprint:6, populatedPlan:6, selectedsupport:6, printEarly:5, print60:5, rawcomplete:5, awaken:5, reserveentry:6, activewaiting:5, swap:6, attack:6, autoreplacement:6, finaldefeat:6, Draw:6, guaranteedstarterreceipt:0, 'HC150-RM':6 };
const coreExpected = {
  'combined-second-plan':{player:{cinder:'Active',aquafin:'Unspent',mossmunk:'Unspent'},rival:{cinder:'Active',aquafin:'Unspent',mossmunk:'Unspent'},cards:['suit','gem','surge','raw'],backs:4,locked:false,rivalQueue:'EMPTY',gear:false},
  'equipment-auto-fit':{player:{cinder:'Active',aquafin:'Ready',mossmunk:'Queued'},rival:{cinder:'Active',aquafin:'Ready',mossmunk:'Queued'},cards:['gem','surge','raw','heated'],backs:4,locked:true,rivalQueue:'1: Suit · 2: Mossmunk',gear:true},
  'auto-replacement':{player:{cinder:'Active',aquafin:'Defeated',mossmunk:'Ready'},rival:{cinder:'Active',aquafin:'Ready',mossmunk:'Ready'},cards:['gem','raw','heated'],backs:3,locked:true,rivalQueue:'EMPTY',gear:false}
};
const coreCardExpected={raw:{label:'Raw Filament +2',aria:'Raw Filament, cost 0, gain 2 filament'},heated:{label:'Heated Spool +3',aria:'Heated Spool, cost 0, gain 3 filament'},suit:{label:'Full Suit · 2',aria:'Full Suit, cost 2'},gem:{label:'Iron Gem · 2',aria:'Iron Gem, cost 2'},surge:{label:'Forge Surge · 2',aria:'Forge Surge, cost 2'}};
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
    const coreGear=[...document.querySelectorAll('.core-printer')].filter(visible);
    const coreGearRects=coreGear.map(element=>stageRect(element));
    const coreGearExpected={rival:[84.95,204.20,156.83,156.83],player:[84.95,1181.00,156.83,156.83]};
    const coreGearGeometry=coreGear.every(element=>exactRect(element,coreGearExpected[element.dataset.gearOwner]));
    const coreShadows=[...document.querySelectorAll('.core-shadow')].filter(visible);
    const coreShadowGeometry=coreShadows.length===2 && exactRect(query('.core-shadow.rival'),[107.87,325.10,111.13,14.70]) && exactRect(query('.core-shadow.player'),[107.87,1302.80,111.13,14.70]);
    const coreQueues=Object.fromEntries([...document.querySelectorAll('[data-core-queue]')].filter(visible).map(element=>[element.dataset.coreQueue,element.textContent.trim()]));
    const coreActiveGeometry=exactRect(query('.core-active.rival'),[369.19,369.66,202.60,270.15]) && exactRect(query('.core-active.player'),[369.19,699.93,202.60,270.15]);
    const coreReserveMiniExpected={r1:[399.50,169.30,86.60,115.43],r2:[706.60,169.60,86.60,115.43],p1:[399.50,1130.10,86.60,115.43],p2:[706.60,1129.00,86.60,115.43]};
    const coreReserveMiniGeometry=[...document.querySelectorAll('.core-reserve .core-mini')].filter(visible).every(element=>{const owner=['r1','r2','p1','p2'].find(value=>element.parentElement.classList.contains(value));return Boolean(owner)&&exactRect(element,coreReserveMiniExpected[owner]);});
    const coreGeometry=(coreState ? coreActiveGeometry && coreReserveMiniGeometry && exactRect(query('.core-active-caption.rival'),[279.40,655.10,380.70,58.80]) && exactRect(query('.core-active-caption.player'),[279.40,953.90,380.70,58.80]) && exactRect(query('.core-side-ink'),[22.90,539.10,230.40,375.70]) && exactRect(query('.core-queue.rival'),[347.90,346.40,441.10,44.10]) && exactRect(query('.core-queue.player'),[295.70,1290.60,599.60,44.10]) && coreShadowGeometry && (!coreGear.length || coreGearGeometry) : true);
    return {
      nativeTextCount:[...document.querySelectorAll('.native,.card-name,.copy,.queue-item,.action,.kit-chip,.kit-magazine,.receipt-copy,.receipt-copy h2,.receipt-copy p,.grant-caption,.starter .back,.forge-center,.system-button,.settings-dial,.core-active-caption,.core-queue,.core-side-ink,.core-label,.core-token')].filter(element => visible(element) && element.textContent.trim()).length,
      figures:[...document.querySelectorAll('.figurine')].filter(visible).length, activeCount:[...document.querySelectorAll('.enemy-active,.player-active')].filter(visible).length, reserveCount:[...document.querySelectorAll('.reserve')].filter(visible).length,
      hasFixtureFigures:query('#screen').hasAttribute('data-expected-figures'), fixtureFigures:Number(query('#screen').dataset.expectedFigures || 0),
      cards:[...document.querySelectorAll('.card')].filter(visible).length,
      roster:[...document.querySelectorAll('.roster-card')].filter(visible).length,
      kitCards:[...document.querySelectorAll('.kit-chip')].filter(visible).length,
      teamArt:teamMinis.length, teamCreatures:teamBays.map(element=>element.dataset.creature || ''), duplicateMarked:Boolean(query('.team-bay.invalid')),
      teamGeometry, kitFaces:kitFaces.length, kitCounts:kitFaces.map(element=>Number(element.dataset.kitCount || 0)), kitTallies, kitGeometry, folioText:query('.book-order') ? query('.book-order').textContent : '', glyphsFit, folioOwnerPass, glyphDiagnostics,
      systemState, systemOwnerNames, systemGeometry, systemTextFits, systemTextValues:systemText.map(element=>element.textContent.trim()), systemTextDiagnostics:[...systemText,...systemOwners].map(element=>({name:element.dataset.navOwner || element.className,scrollWidth:element.scrollWidth,clientWidth:element.clientWidth,scrollHeight:element.scrollHeight,clientHeight:element.clientHeight})), focusProof, focusedOwner:active?.dataset?.navOwner || '', genericWorkshopActions:[...document.querySelectorAll('.workshop .action')].filter(visible).length, disabledSystemOwners:systemOwners.filter(element=>element.disabled).map(element=>element.dataset.navOwner || ''), reducedMotionChecked:query('.settings-dial')?.getAttribute('aria-checked') || '', coreState, coreRecords, coreRecordMap, coreTextFits, coreTextDiagnostics:coreText.map(element=>({text:element.textContent.trim(),scrollWidth:element.scrollWidth,clientWidth:element.clientWidth,scrollHeight:element.scrollHeight,clientHeight:element.clientHeight})), coreInputs:coreInputs.map(element=>({kind:element.dataset.coreInput,disabled:element.disabled})), coreHand:[...document.querySelectorAll('.core-card')].filter(visible).length, coreCards:[...document.querySelectorAll('.core-card')].filter(visible).map(element=>({id:element.dataset.coreCard,label:element.textContent.trim(),aria:element.getAttribute('aria-label') || ''})), coreGear:coreGear.map(element=>({job:element.dataset.jobType,target:element.dataset.lockedTarget,owner:element.dataset.gearOwner,filter:getComputedStyle(element.querySelector('.core-gear')).filter})), coreGearGeometry, coreQueues, coreGeometry, duplicateStatusRows:document.querySelectorAll('.status-records').length, coreThirdBay:document.querySelectorAll('.core-reserve.r3,.core-reserve.p3').length,
      controls, viewport, screen,
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
  const terminalState = ['win-result-m2','loss-result-m2','draw-result-m2'].includes(state);
  const starterState = state.startsWith('starter-');
  const editorState = ['teamvalid','teaminvalid','team-empty','team-one','supportkit','supportkit-excluded'].includes(state);
  const workshopState = ['workshop-prototype-nav','preflight-error','recovery','focus-sheet','reduced-motion'].includes(state);
  const battleState = !editorState && !workshopState && state !== 'guaranteedstarterreceipt' && !terminalState && !starterState;
  const expectedStarterPhase = starterState ? state.slice('starter-'.length) : '';
  const starterBackground = ['starter-choice','starter-inspect'].includes(state) ? actual.backgroundImages.screen.includes('starter-blueprint-desk-v4.png') : actual.backgroundImages.screen.includes('enclosed-forge-static-master-v1.png');
  const backgroundPass = (starterState ? starterBackground : workshopState ? (state === 'recovery' ? actual.backgroundImages.screen.includes('SY-02-recovery-ledger-text-free-v2.png') : ['focus-sheet','reduced-motion','preflight-error'].includes(state) ? actual.backgroundImages.screen.includes('ST-01-settings-instrument-text-free-v3.png') : actual.backgroundImages.screen.includes('workshop-backplate-text-free-v1.png')) : (state === 'guaranteedstarterreceipt' || terminalState) ? actual.backgroundImages.screen.includes('BA-05-result-receipt-v4.png') : editorState ? actual.backgroundImages.screen.includes('TM-R1-team-support-workbench-text-free-v1.png') : actual.backgroundImages.screen.includes('BA-R1-team-autobattle-chassis-text-free-v1.png')) && actual.backgroundLoaded.screen && (actual.cards ? actual.backgroundImages.card.includes('support_cards_') && actual.backgroundLoaded.card : true) && (actual.kitCards ? actual.backgroundImages.kit.includes('support_cards_') && actual.backgroundLoaded.kit : true) && (battleState ? actual.backgroundImages.privateBack.includes('support_card_back_source_v1.png') && actual.backgroundLoaded.privateBack : true) && (terminalState ? actual.nestedReceiptCount === 0 && actual.resultScreenCount === 1 : true) && (actual.figures ? (actual.backgroundImages.sprite.includes('battle_facing') || actual.backgroundImages.sprite.includes('voltwig_sprite_sheet')) && actual.backgroundLoaded.sprite : true) && (actual.printedInPrinter ? (actual.backgroundImages.printed.includes('battle_facing') || actual.backgroundImages.printed.includes('voltwig_sprite_sheet')) && actual.backgroundLoaded.printed : true);
  const starterPass = !starterState || (actual.figures === 0 && actual.cards === 0 && actual.privateBacks === 0 && actual.printedInPrinter === 0 && actual.starterPhase === expectedStarterPhase && (['choice','inspect'].includes(expectedStarterPhase) ? actual.starterBlueprints === 1 && actual.forgeSolid === 0 : expectedStarterPhase === 'voucher' ? actual.starterBlueprints === 0 && actual.forgeSolid === 0 && actual.forgeWire === 0 : ['awaken','rawcomplete'].includes(expectedStarterPhase) ? actual.forgeSolid === 1 && actual.forgeWire === 0 : actual.forgeSolid === 1 && actual.forgeWire === 1));
  const teamExpectedArtwork={ 'team-empty':0, 'team-one':1, teaminvalid:3, teamvalid:3, supportkit:3, 'supportkit-excluded':3 };
  const teamEditorPass = !Object.hasOwn(teamExpectedArtwork,state) || (actual.teamArt === teamExpectedArtwork[state] && actual.teamGeometry && (state !== 'teamvalid' || new Set(actual.teamCreatures).size === 3 && actual.teamCreatures.every(Boolean)) && (state !== 'teaminvalid' || actual.duplicateMarked && actual.teamCreatures.filter(id=>id === 'cinder').length === 2));
  const kitEditorPass = !editorState || (actual.kitFaces === 4 && actual.kitGeometry && actual.kitCounts.length === 4 && (!state.startsWith('supportkit') || (actual.kitTallies.length === 5 && actual.kitTallies.reduce((sum,value)=>sum+value,0) === 15 && actual.folioText.includes('Heated Spool ×2'))));
  const systemExpectedOwners={ 'workshop-prototype-nav':['forge','team','kit','battle','settings','back'], 'preflight-error':['back','context'], 'focus-sheet':['back','context'], 'reduced-motion':['back','dial','context'], recovery:['back','continue'] };
  const systemPass = !workshopState || (actual.systemGeometry && actual.systemTextFits && actual.genericWorkshopActions === 0 && actual.disabledSystemOwners.length === 0 && actual.systemOwnerNames.join('|') === systemExpectedOwners[state].join('|') && (state !== 'focus-sheet' || actual.focusProof && actual.focusedOwner === 'context') && (state !== 'reduced-motion' || actual.reducedMotionChecked === 'true') && (state !== 'recovery' || actual.systemTextValues.join(' ').replace(/\.No/g,'. No').includes('Recovered Team and Kit preview. No legacy save mutation.')));
  const coreFixture = coreExpected[state];
  const expectedCoreRecords = coreFixture ? Object.fromEntries(Object.entries(coreFixture).filter(([key])=>key==='player'||key==='rival').flatMap(([seat,records])=>Object.entries(records).map(([creature,status])=>[`${seat}:${creature}`,status]))) : {};
  const coreStatusPass = !coreFixture || (actual.coreRecords.length === 6 && Object.keys(actual.coreRecordMap).length === 6 && Object.entries(expectedCoreRecords).every(([key,status])=>actual.coreRecordMap[key] === status));
  const coreCardPass = !coreFixture || (actual.coreHand === coreFixture.cards.length && actual.coreCards.length === coreFixture.cards.length && actual.coreCards.every((card,index)=>card.id === coreFixture.cards[index] && card.label === coreCardExpected[card.id].label && card.aria.startsWith(coreCardExpected[card.id].aria)) && actual.coreCards.filter(card=>card.id === 'raw' || card.id === 'heated').every(card=>card.label === coreCardExpected[card.id].label && card.aria.startsWith(coreCardExpected[card.id].aria)));
  const coreInputPass = !coreFixture || (coreCardPass && actual.privateBacks === coreFixture.backs && actual.coreInputs.length >= coreFixture.cards.length + (coreFixture.locked ? (state === 'equipment-auto-fit' ? 2 : 3) : 1) && actual.coreInputs.every(input=>input.kind === 'run' || input.kind === 'hand' || input.kind === 'reserve') && actual.coreInputs.every(input=>input.disabled === coreFixture.locked));
  const coreGearPass = !coreFixture || (coreFixture.gear ? actual.coreGear.length === 2 && actual.coreGear.every(gear=>gear.job === 'equipment' && gear.target === 'cinder' && gear.filter.includes('gear-alpha-mask')) && actual.coreGearGeometry : actual.coreGear.length === 0);
  const coreBattlePass = !coreFixture || (actual.coreState === state && coreStatusPass && coreInputPass && actual.duplicateStatusRows === 0 && actual.coreThirdBay === 0 && actual.coreQueues.rival === coreFixture.rivalQueue && actual.coreGeometry && actual.coreTextFits && coreGearPass);
  const statePass = actual.figures === expected && actual.activeHolderCount === 0 && uniqueIdentities && starterPass && teamEditorPass && kitEditorPass && systemPass && coreBattlePass && (battleState && !coreFixture ? actual.privateBacks === 4 : true) && (terminalState ? actual.cards === 0 && actual.printedInPrinter === 0 && actual.privateBacks === 0 : true) && (state === 'choosefirstprint' ? actual.printedInPrinter === 0 : true) && (['printEarly','print60','rawcomplete','awaken'].includes(state) ? actual.printedInPrinter === 2 : true) && (['activewaiting','activewaitingrun'].includes(state) ? actual.printedInPrinter === 0 : true) && (['finaldefeat','Draw'].includes(state) ? actual.cards === 0 : true);
  const textNodePass = actual.nativeTextCount >= ((state === 'guaranteedstarterreceipt' || workshopState) ? 3 : 4);
  const editorFontPass = !editorState || [actual.fonts.editorOrder,actual.fonts.editorEligibility,actual.fonts.editorStatus,actual.fonts.teamCaption,actual.fonts.kitName,actual.fonts.kitCount].every(value => value >= 15.5);
  const systemFontValues = state === 'workshop-prototype-nav' ? [actual.fonts.systemButton] : state === 'recovery' ? [actual.fonts.systemButton,actual.fonts.recoveryMessage] : [actual.fonts.systemButton,actual.fonts.settingsHeader,actual.fonts.settingsBody,state === 'reduced-motion' ? actual.fonts.settingsDial : 16];
  const systemFontPass = !workshopState || systemFontValues.every(value => value >= 15.5);
  const primaryFontPass = workshopState || coreFixture ? true : starterState ? actual.fonts.primary >= 15.5 : actual.fonts.action >= 15.5;
  const coreFontPass = !coreFixture || [actual.fonts.heading,actual.fonts.coreActive,actual.fonts.coreReserve,actual.fonts.coreHand,actual.fonts.coreSide,actual.fonts.corePrivate].every(value=>value >= 15.5);
  const textPass = textNodePass && editorFontPass && systemFontPass && primaryFontPass && coreFontPass && (actual.cards ? actual.fonts.hand >= 15.5 : true) && (actual.figures ? (actual.activeCount ? actual.fonts.active >= 15.5 : true) && (actual.reserveCount ? actual.fonts.reserve >= 15.5 : true) : true) && (battleState && !coreFixture ? actual.fonts.heading >= 14 && actual.fonts.queue >= 15.5 : true) && Boolean(actual.backgroundImages.privateBack || !battleState);
  const tallPass = size.name !== '720x1600' || (actual.safeTop >= 24 && actual.safeBottom >= 24 && actual.screen.y === actual.safeTop && actual.screen.bottom <= actual.viewport.bottom - actual.safeBottom + 1);
  const clipPass = actual.clippedText.length === 0 && actual.glyphsFit;
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
