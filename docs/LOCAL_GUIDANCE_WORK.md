# Local guidance and weekly requests

Z's scope: enlarge title-screen small text; protect essential tools from gifts; put Oren's posting first; guide the player through Oren → Rowan's seven-day, ten-log axe agreement → fishing-pole reward; make Moss a local guide, with copper/protection/Bram as his first post-welcome topic; exchange three moon turnips for Bram's sword, with Iona/astronomer hints; mayor and Neral point to Moss and the board; Dain offers an expensive 250-crown sword and practical alternatives; four board positions with a twenty-request weekly pool.

Audit: `dialog()` currently offers any selected inventory item as a gift; `give_gift()` has no protected-item check. The board has four fixed entries with the ladder first. Oren incorrectly treats an accepted request as proof the player carries the wood. Rowan and Bram currently hand out tools without conditions. Existing relationship/quest-history systems will be reused. New persistent request and axe-loan state uses a strict new save version, without migrations. Work branch: wip/local-guidance-and-weekly-jobs; starting working tree was clean.

Z confirmed weekly tuning: modest crown rewards and +3 friendship per delivery, unfinished requests expire at weekly refresh, and seasonal/locked resources are filtered. Permanent firewood/ladder postings remain until completed; weekly requests fill the other available positions and newly vacated positions. Deadline penalty is applied once; the axe is never confiscated and late repayment remains possible.

Implemented: protected tools in both gift UI and state validation; larger title text; revised local conversations and equipment trades; seven-day axe deadline and repayment; a four-position board backed by a twenty-request pool. Accepted jobs appear in the Crew Log and are handed in through recipient dialogue. Completed and expired jobs remain in character history. Buying Dain's sword does not falsely complete Bram's turnip trade. Save schema 18 persists request history and agreements, with no older-save migration.

Verification is complete: 109 native test programs with 3,194 passing checks, ten Python asset checks, native startup smoke and seven GUI captures. `internal/verification/local-guidance-final-checks.log` combines the broad audit with clean focused reruns; earlier failures remain in `local-guidance-audit/`. Captures cover title, board, Oren, Rowan, Moss, Bram and Dain. The audit found an old controls-test assumption that Wildgrowth always ripens a crop on Chaos day; the input-binding check now uses Bough to isolate controls from random weekday strength. The older interior test now pays Bram three turnips through the actual dialogue. Axe tests cover exact deadline persistence, timely repayment, one late penalty, retained ownership and late repayment. No artwork or dependencies changed.

## Weekly request pool

Each delivery also grants +3 friendship. Fish jobs unlock after Oren's pole reward, wood jobs after receiving Rowan's axe, and mined-material jobs after collecting the cave pickaxe. Berry jobs require spring/summer; apple jobs require autumn. The remaining supplies are normally obtainable in town or through farming.

| Requester | Supplies | Crowns |
| --- | --- | ---: |
| Tavi | 5 pond silverfin | 35 |
| Mara Bell | 5 berries | 25 |
| Saeren | 5 star bulbs | 40 |
| Moss | 3 moon turnips | 24 |
| Corin | 5 berries | 25 |
| Elin Reed | 4 moon turnips | 28 |
| Jory Reed | 6 logs | 24 |
| Pip Reed | 3 apples | 24 |
| Iona | 4 star bulbs | 36 |
| Finch | 2 copper ore | 24 |
| Dain | 3 coal | 30 |
| Tomas Bell | 5 logs | 20 |
| Rafe | 3 pond silverfin | 24 |
| Brother Aven | 4 berries | 20 |
| Oren | 4 logs | 18 |
| Bram | 3 moon turnips | 24 |
| Rowan | 5 stone | 20 |
| Neral | 2 loaves of bread | 20 |
| Mayor Alder | 4 apples | 32 |
| Nessa Bell | 2 copper ore | 24 |
