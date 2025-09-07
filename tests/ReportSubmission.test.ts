import { describe, it, expect, beforeEach } from "vitest";

const ERR_NOT_AUTHORIZED = 100;
const ERR_INVALID_HASH = 101;
const ERR_INVALID_DESCRIPTION = 102;
const ERR_INVALID_SEVERITY = 103;
const ERR_INVALID_LOCATION = 104;
const ERR_REPORT_ALREADY_EXISTS = 105;
const ERR_REPORT_NOT_FOUND = 107;
const ERR_INVALID_BOUNDARIES = 111;
const ERR_MAX_REPORTS_EXCEEDED = 114;
const ERR_INVALID_CATEGORY = 115;
const ERR_INVALID_EVIDENCE_COUNT = 116;
const ERR_INVALID_IMPACT_LEVEL = 117;
const ERR_INVALID_WEATHER_IMPACT = 118;
const ERR_INVALID_AFFECTED_POPULATION = 119;
const ERR_INVALID_EMERGENCY_LEVEL = 120;
const ERR_FEE_NOT_PAID = 122;
const ERR_INVALID_EVIDENCE_HASH = 123;
const ERR_DUPLICATE_EVIDENCE = 124;
const ERR_INVALID_UPDATE_HASH = 113;

interface Location {
  lat: number;
  lon: number;
}
interface Boundaries {
  minLat: number;
  maxLat: number;
  minLon: number;
  maxLon: number;
}
interface Report {
  hash: string;
  description: string;
  severity: number;
  location: Location;
  boundaries: Boundaries;
  timestamp: number;
  reporter: string;
  category: string;
  evidenceHashes: string[];
  impactLevel: number;
  weatherImpact: string;
  affectedPopulation: number;
  emergencyLevel: number;
  status: string;
}
interface ReportUpdate {
  updateHash: string;
  updateDescription: string;
  updateSeverity: number;
  updateTimestamp: number;
  updater: string;
}

class ReportSubmissionMock {
  state: {
    nextReportId: number;
    maxReports: number;
    reports: Map<number, Report>;
    reportUpdates: Map<number, ReportUpdate>;
    reportsByHash: Map<string, number>;
  };
  blockHeight = 0;
  caller = "ST1TEST";
  tokenBalance = 1000;

  constructor() {
    this.reset();
  }
  reset() {
    this.state = {
      nextReportId: 0,
      maxReports: 10000,
      reports: new Map(),
      reportUpdates: new Map(),
      reportsByHash: new Map(),
    };
    this.blockHeight = 0;
    this.caller = "ST1TEST";
    this.tokenBalance = 1000;
  }

  submitReport(
    reportHash: string,
    description: string,
    severity: number,
    location: Location,
    boundaries: Boundaries,
    category: string,
    evidenceHashes: string[],
    impactLevel: number,
    weatherImpact: string,
    affectedPopulation: number,
    emergencyLevel: number
  ) {
    const nextId = this.state.nextReportId;
    if (nextId >= this.state.maxReports) return { ok: false, value: ERR_MAX_REPORTS_EXCEEDED };
    if (reportHash.length !== 64 || !/^[0-9a-fA-F]+$/.test(reportHash)) return { ok: false, value: ERR_INVALID_HASH };
    if (!description || description.length > 1000) return { ok: false, value: ERR_INVALID_DESCRIPTION };
    if (severity < 1 || severity > 10) return { ok: false, value: ERR_INVALID_SEVERITY };
    if (location.lat < -90 || location.lat > 90 || location.lon < -180 || location.lon > 180)
      return { ok: false, value: ERR_INVALID_LOCATION };
    if (boundaries.minLat > boundaries.maxLat || boundaries.minLon > boundaries.maxLon)
      return { ok: false, value: ERR_INVALID_BOUNDARIES };
    if (!["natural-disaster", "conflict", "public-emergency", "health-crisis"].includes(category)) return { ok: false, value: ERR_INVALID_CATEGORY };
    if (evidenceHashes.length < 1 || evidenceHashes.length > 10) return { ok: false, value: ERR_INVALID_EVIDENCE_COUNT };
    if (evidenceHashes.some((h, i) => evidenceHashes.indexOf(h) !== i)) return { ok: false, value: ERR_DUPLICATE_EVIDENCE };
    if (impactLevel < 1 || impactLevel > 5) return { ok: false, value: ERR_INVALID_IMPACT_LEVEL };
    if (!["none", "mild", "severe"].includes(weatherImpact)) return { ok: false, value: ERR_INVALID_WEATHER_IMPACT };
    if (affectedPopulation > 10000000) return { ok: false, value: ERR_INVALID_AFFECTED_POPULATION };
    if (emergencyLevel < 1 || emergencyLevel > 3) return { ok: false, value: ERR_INVALID_EMERGENCY_LEVEL };
    if (this.state.reportsByHash.has(reportHash))
      return { ok: false, value: ERR_REPORT_ALREADY_EXISTS };
    if (this.tokenBalance < 500) return { ok: false, value: ERR_FEE_NOT_PAID };
    this.tokenBalance -= 500;

    const newReport: Report = {
      hash: reportHash,
      description,
      severity,
      location,
      boundaries,
      timestamp: this.blockHeight,
      reporter: this.caller,
      category,
      evidenceHashes,
      impactLevel,
      weatherImpact,
      affectedPopulation,
      emergencyLevel,
      status: "pending",
    };
    this.state.reports.set(nextId, newReport);
    this.state.reportsByHash.set(reportHash, nextId);
    this.state.nextReportId++;
    return { ok: true, value: nextId };
  }

  getReport(id: number) {
    const report = this.state.reports.get(id);
    return report ? { ok: true, value: report } : { ok: false, value: null };
  }

  updateReport(id: number, updateHash: string, desc: string, severity: number) {
    const report = this.state.reports.get(id);
    if (!report) return { ok: false, value: ERR_REPORT_NOT_FOUND };
    if (report.reporter !== this.caller) return { ok: false, value: ERR_NOT_AUTHORIZED };
    if (updateHash.length !== 64 || !/^[0-9a-fA-F]+$/.test(updateHash)) return { ok: false, value: ERR_INVALID_UPDATE_HASH };
    if (!desc || desc.length > 1000) return { ok: false, value: ERR_INVALID_DESCRIPTION };
    if (severity < 1 || severity > 10) return { ok: false, value: ERR_INVALID_SEVERITY };
    if (this.state.reportsByHash.has(updateHash) && this.state.reportsByHash.get(updateHash) !== id)
      return { ok: false, value: ERR_REPORT_ALREADY_EXISTS };

    const oldHash = report.hash;
    this.state.reportsByHash.delete(oldHash);
    this.state.reportsByHash.set(updateHash, id);

    const updated: Report = { ...report, hash: updateHash, description: desc, severity: severity, timestamp: this.blockHeight };
    this.state.reports.set(id, updated);
    this.state.reportUpdates.set(id, {
      updateHash,
      updateDescription: desc,
      updateSeverity: severity,
      updateTimestamp: this.blockHeight,
      updater: this.caller,
    });
    return { ok: true, value: true };
  }
}

describe("ReportSubmission", () => {
  let contract: ReportSubmissionMock;
  beforeEach(() => (contract = new ReportSubmissionMock()));

  it("submits a valid report", () => {
    const result = contract.submitReport(
      "a".repeat(64),
      "Major flood",
      7,
      { lat: 40, lon: -74 },
      { minLat: 39, maxLat: 41, minLon: -75, maxLon: -73 },
      "natural-disaster",
      ["b".repeat(64)],
      4,
      "severe",
      50000,
      2
    );
    expect(result.ok).toBe(true);
    expect(contract.getReport(0).value?.description).toBe("Major flood");
  });

  it("rejects invalid hash", () => {
    expect(
      contract.submitReport("bad", "desc", 3, { lat: 0, lon: 0 }, { minLat: -1, maxLat: 1, minLon: -1, maxLon: 1 }, "natural-disaster", ["b".repeat(64)], 1, "none", 100, 1)
    ).toEqual({ ok: false, value: ERR_INVALID_HASH });
  });

  it("rejects invalid location", () => {
    expect(
      contract.submitReport("a".repeat(64), "desc", 3, { lat: 100, lon: 0 }, { minLat: -1, maxLat: 1, minLon: -1, maxLon: 1 }, "natural-disaster", ["b".repeat(64)], 1, "none", 100, 1)
    ).toEqual({ ok: false, value: ERR_INVALID_LOCATION });
  });

  it("rejects duplicate report", () => {
    contract.submitReport("a".repeat(64), "desc", 3, { lat: 0, lon: 0 }, { minLat: -1, maxLat: 1, minLon: -1, maxLon: 1 }, "natural-disaster", ["b".repeat(64)], 1, "none", 100, 1);
    expect(
      contract.submitReport("a".repeat(64), "desc2", 3, { lat: 0, lon: 0 }, { minLat: -1, maxLat: 1, minLon: -1, maxLon: 1 }, "natural-disaster", ["c".repeat(64)], 1, "none", 100, 1)
    ).toEqual({ ok: false, value: ERR_REPORT_ALREADY_EXISTS });
  });

  it("updates a valid report", () => {
    contract.submitReport("a".repeat(64), "old", 2, { lat: 0, lon: 0 }, { minLat: -1, maxLat: 1, minLon: -1, maxLon: 1 }, "natural-disaster", ["b".repeat(64)], 1, "none", 100, 1);
    const res = contract.updateReport(0, "b".repeat(64), "new", 4);
    expect(res.ok).toBe(true);
    expect(contract.getReport(0).value?.description).toBe("new");
  });

  it("rejects update for non-existent report", () => {
    expect(contract.updateReport(99, "b".repeat(64), "x", 3)).toEqual({ ok: false, value: ERR_REPORT_NOT_FOUND });
  });
});