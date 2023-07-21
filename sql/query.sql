-- SELECT slice.name AS slice_name, ROUND((slice.ts-xxx)/1e6, 2) as start_time, ROUND((slice.ts+slice.dur-xxx)/1e6,2) as end_time, ROUND(slice.dur/1e6,2) as dur_time, slice.ts,
SELECT slice.name AS slice_name, ROUND(slice.ts/1e6, 2) as start_time, ROUND((slice.ts+slice.dur)/1e6,2) as end_time, ROUND(slice.dur/1e6,2) as dur_time, slice.ts,
pid, tid, process.name AS proc_name, thread.name AS thread_name, 
slice.dur,slice.track_id
FROM slice
LEFT OUTER JOIN process_track ON slice.track_id = process_track.id
LEFT OUTER JOIN process USING(upid)
LEFT OUTER JOIN thread_track ON slice.track_id = thread_track.id
LEFT JOIN thread USING(utid)
WHERE (
) AND slice.ts >= 0 ORDER BY slice.ts;