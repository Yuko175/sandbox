export function download_excel() {
  // Create a simple Excel-compatible CSV content with "test" in A1
  const csvContent = "test\n";

  // Create a Blob
  const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8" });

  // Create a download link
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = "data.csv";

  // Trigger download
  link.click();

  // Cleanup
  URL.revokeObjectURL(link.href);
}

let __ws_intervals = [];

export function start_interval(cb, ms) {
  if (__ws_intervals[0]) clearInterval(__ws_intervals[0]);
  const id = setInterval(() => cb(), ms);
  __ws_intervals[0] = id;
}

export function stop_interval() {
  if (__ws_intervals[0]) {
    clearInterval(__ws_intervals[0]);
    __ws_intervals[0] = undefined;
  }
}

export function start_timeout(cb, ms) {
  setTimeout(() => cb(), ms);
}

export function format_mmss(v) {
  const total_cs = Math.round(v * 100);
  const mins = Math.floor(total_cs / 6000);
  const secs = Math.floor((total_cs % 6000) / 100);
  const cs = total_cs % 100;
  const mm = String(mins).padStart(2, "0");
  const ss = String(secs).padStart(2, "0");
  const cc = String(cs).padStart(2, "0");
  return `${mm}:${ss}.${cc}`;
}
