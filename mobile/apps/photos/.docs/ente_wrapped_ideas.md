Photos taken statistics:

- Total photos clicked. "If printed, your photos would make a stack X meters tall"
- Total videos clicked
- Storage: you captured X GB of memories .
- Photo velocity: average photos per day, with your most and least active months
- GitHub like contribution-graph based on photo capture dates
- portrait vs. landscape
- monthly timeline
- distribution across 24 hours ("afternoon is your time")
- distribution across weekdays
- distribution across seasons
- Longest photo streak
  - _Compute:_ consecutive days with ≥1 capture.
  - _Copy:_ “You kept the lens alive for **{N} days** straight.”
- Biggest photo day
  - _Compute:_ max photos on a single calendar day; show date + cluster preview.
  - _Copy:_ “**{Date}** was your most snapped day.”
- Longest no‑photo gap
  - Compute: max gap between capture datetimes.
  - Copy: “You took a breather for {N} days.”
- Photos vs last year
  - Compute: % change.
  - Copy: “Up {+X%} from 2024, you're becoming a photographer pro” / " {+X%} less than 2024, you're becoming zen!”
- Month‑over‑month “most improved”
  - Compute: MoM % changes; highlight top jump.
  - Copy: “{Month} was your comeback month.”
- Golden vs Blue hour
  - Compute: classify captures vs local sunrise/sunset (approx by location; fallback to hour buckets).
  - Copy: “A golden hour chaser: {X}% of your shots.”
- Burst moments
  - Compute: detect sequences within ~1s with similar EXIF.
  - Copy: “{N} bursts—you don’t miss the action.”
- Front vs rear camera (selfie tendency)
  - Compute: EXIF lens/camera facing or focal metadata heuristics.
  - Copy: “{X}% were front‑camera moments.”

Quick stories:

- First photo of the year
-

People and relationships:

- Most photographed person (if one person named)
  - Compute: largest face cluster this year.
  - Copy: “{Name} starred in your year.”
- Your 3 top most photographed persons (if at least 3 people named)
  - Make into a new collage of the three
- Captured N moments with your loved ones!
  - Compute: number of photos containing named persons (that aren't (only) the user)
- New faces met
  - Compute: face clusters (minimum size of 10 photos) appearing first time in 2025.
  - Copy: “{N} new faces joined your story.”
- Group vs solo
  - Compute: faces per photo threshold (≥3 = group).
  - Copy: “{X}% group photos—memories shared.”
-

Places and movement:

- - **“Then & Now” re‑shoots**
  - Compute: same location cluster across years ±30 days; pick best pair.
  - Copy: “Same spot, new story.”
- New places count
  - Compute: unique city/country from clustered GPS; mark first‑ever for library.
  - Copy: “You explored {N} new places.”
- Top photo cities
  - Compute: reverse‑geocode clusters; top 3.
  - Copy: “Your camera loved {City 1}, {City 2}, {City 3}.”
- Most photogenic spot
  - Compute: densest 100m geohash block; show map dot & micro‑gallery.
  - Copy: “You kept returning to {Spot}.”
- Altitude range: highest and lowest elevation photos (if GPS data available)

Visual styles and aesthetics:

- Showing some blurry imperfect photos
  - Use the blurry scores of faces
  - Preferably use named persons
- Your year in color
  - Use CLIP embeddings of "Photo strongly coloured X" and search with tight threshold
  - Copy: “2025 looked like this” (show swatches strip).
- Monochrome moments
  - Use CLIP embeddings again
  - Copy: “{N} black‑and‑white frames.”
- Panorama love
  - Compute: aspect ratio > ~2.2 or iOS pano flag.
  - Copy: “{N} wide‑as‑the-sky panoramas.”
- Biggest shot
  - Highest resolution shot
  - Copy: “Your biggest click.”
- Aesthetic top picks
  - Run multiple CLIP embeddings with different positive text queries. Take the intersection of the ones with highest similarity
  - Copy: “Pure wow”

Camera & technique:

- New device added (if applicable only)
  - Compute: first‑seen camera model in 2025.
  - Copy: “Hello, {Model}—first light on {Date}.”
- Live Photo / Motion Photo rate (if present)
  - Compute: vendor tags.
  - Copy: “{X}% of your photos move.”

Content & Scenes

- Pet index (cats/dogs)
  - Compute using CLIP embeddings; counts & top months.
  - Copy: “{N} pet portraits - {type of pet} is your favorite
- Foodie score
  - Compute: food classifier.
  - Copy: “{N} delicious plates captured.”

Curation & organization:

- Favorites you marked
  - Compute: count & top month.
  - Copy: “You starred {N} favorites.”
- Albums created / most‑filled album
  - Compute: album stats.
  - Copy: “You created {N} new albums. Your busiest album: {Album}.”
- Edits made (crop/exposure/filters)
  - Compute: edit metadata count.
  - Copy: “{N} photos got a glow‑up.”
- Share & collaboration
  - Compute: shared albums created, contributors added.
  - Copy: “You shared {X} memories with {N} people.”
- Shared images versus own images
  - You shared way more with other than others shared with you: wow, you're really the photographer of the group!

Narrative moments:

- Top 3 events
  - Compute: time‑and‑place clustering; rank by density & variety.
  - Copy: “Your year’s big three.”
- “Best of” reel
  - Compute: combine high CLIP similarity to positive queries + high face scores of named persons + diversity (place/time/subject) + favorites (if applicable)
  - Copy: “Your top 25—sealed for 2025.”

End by giving everyone a badge/avatar of what they are based on (some statistic of) their photos. This should be fun and tempt the user to share.
