Absolutely, Emilio. I think this is worth documenting as an **open engineering experiment**, rather than pretending we have already derived a universal rule. The important result is not merely “v02 was faster”; it is that the experiment exposed a non-obvious performance question worth investigating systematically later.

# Bash Data Representation Performance Experiment

### Variables vs. Temporary Files vs. Streaming Pipelines

**Status:** Open / future investigation
**Primary environment:** Bash under Cygwin
**Origin:** `vl.hvti` refactoring and optimization

## 1. Purpose

During the refactoring of a Bash-based lot viewer/report generator, an unexpected performance result was observed.

A natural assumption was that capturing the output of a command into a Bash variable and subsequently processing that data from memory should be faster than writing the same data to a temporary file and repeatedly reading the file.

The experiment showed the opposite.

A version using a temporary file was measurably faster than two versions keeping the complete dataset in Bash variables.

This raises a broader engineering question:

> **Under what circumstances is it more efficient to retain intermediate data in a Bash variable, stream it through pipelines, or materialize it as a temporary file?**

The purpose of the future experiment is **not** to prove that files are faster than memory. It is to determine which representation is preferable under different workloads and to establish practical rules of thumb for Bash/system scripting.

---

## 2. Original Problem

`vl.hvti` identifies symbols containing at least one `10.HVT` lot and then displays the complete inventory for each of those symbols.

The original implementation repeatedly invoked `vl.sym`, which itself invoked `view_lots`.

Conceptually:

`view_lots → find HVT symbols → view_lots → symbol 1 → view_lots → symbol 2 → ...`

The objective was to eliminate the repeated execution of `view_lots` while preserving exactly the same output.

---

## 3. Implementations Tested

### Version 01 — Original

```bash
function vl.hvti_v01()
{
  view_lots                            \
  | grep --regexp='HVT'                \
  | cut --delimiter='|' --fields=1     \
  | sort                               \
  | uniq                               \
  | for sym in $(cat -); do {
    vl.sym ${sym}; 
    echo -e "<==\n\n";
  } done
  return 0;
}
```

This version repeatedly calls `vl.sym`, and therefore repeatedly executes `view_lots`.

---

### Version 02 — Temporary-file cache

This version executes `view_lots` once and stores the rendered result in a temporary file.

```bash
function vl.hvti_v02()
{
  require_input_data || return 1;

  local fl_view_lots=$(mktemp);

  view_lots > "${fl_view_lots}" || {
    rm -f "${fl_view_lots}";
    return 1;
  }

  while read -r sym; do
    {
      printf "${fmt_hdr}" ${labels};

      grep -e "^${sym}[ |]" "${fl_view_lots}" \
      | sort \
        --field-separator='|' \
        --key=${sort_by_dts} \
      ;
    } \
    | nl --number-width=4;

    echo -e "<==\n\n";

  done < <(
    grep --regexp='10.HVT' "${fl_view_lots}" \
    | cut --delimiter='|' --fields=1 \
    | sort \
    | uniq
  );

  rm -f "${fl_view_lots}";

  return 0;
}
```

This version became the fastest of the tested implementations.

---

### Version 03 — Bash variable

The temporary file was replaced by a Bash variable.

```bash
function vl.hvti_v03()
{
  require_input_data || return 1;

  local lots_table=$(view_lots);

  while read -r sym; do
    {
      printf "${fmt_hdr}" ${labels};
      echo "${lots_table}" \
      | grep -e "^${sym}[ |]"  \
      | sort \
        --field-separator='|' \
        --key=${sort_by_dts} \
      ;
    } \
    | nl --number-width=4;

    echo -e "<==\n\n";

  done < <(
    echo "${lots_table}" \
    | grep --regexp='10.HVT' \
    | cut --delimiter='|' --fields=1 \
    | sort \
    | uniq
  )

  return 0;
}
```

This implementation avoids explicit temporary-file creation but was slower than v02.

---

### Version 04 — Bash variables with precomputed HVT symbols

The latest preferred implementation separates the HVT-symbol extraction into its own variable.

```bash
function vl.hvti()
{
  require_input_data || return 1;

  local lots_table=$(view_lots);

  local hvt_symbols=$(
    echo "${lots_table}" \
    | grep --regexp='10.HVT' \
    | cut --delimiter='|' --fields=1 \
    | sort \
    | uniq \
  );

  echo "${hvt_symbols}" \
  | while read -r sym; do {
    {
      printf "${fmt_hdr}" ${labels};
      echo "${lots_table}" \
      | grep -e "^${sym}[ |]"  \
      | sort \
        --field-separator='|' \
        --key=${sort_by_dts} \
      ;
    } \
    | nl --number-width=4;

    echo -e "<==\n\n";
  } done

  return 0;
}
```

Despite keeping the data entirely in memory from the script's perspective, this was not the fastest implementation.

---

## 4. Observed Results

Twenty-five executions were performed for each version.

The primary metric used was **`real` time**, because it represents elapsed wall-clock time experienced by the user.

| Version | Description                          | Average `real` |
| ------- | ------------------------------------ | -------------: |
| 01      | Original, repeated `view_lots`       |      2.87416 s |
| 02      | Temporary-file cache                 |  **2.25336 s** |
| 03      | Bash variable                        |      2.53352 s |
| 04      | Bash variables + precomputed symbols |      2.54684 s |

The temporary-file implementation was therefore approximately **22% faster than the original** and approximately **11% faster than the best in-memory implementation tested**.

The results were not merely a single anomalous measurement; the averages over 25 executions showed a reasonably consistent difference.

---

## 5. The Unexpected Result

The surprising observation was:

> **The implementation using a temporary file was faster than implementations that retained the complete dataset in Bash memory.**

At first glance this appears counterintuitive.

A simplistic model would suggest:

`RAM → faster than → disk`

However, that model does not accurately describe what was being measured.

The temporary-file implementation does not necessarily perform a physical disk read for every `grep`.

Once a file is read, the operating system may retain its contents in the filesystem/page cache. Subsequent accesses can therefore be served from RAM while still using the filesystem interface.

Consequently, the experiment does **not** establish:

> Disk is faster than memory.

A more defensible interpretation is:

> **A file-backed processing pipeline can be faster than repeatedly manipulating the same large dataset as a Bash string, even when the file's contents are resident in memory through the operating-system cache.**

---

## 6. Why the Bash Variable May Be Expensive

The expression:

```bash
local lots_table=$(view_lots)
```

does not create a zero-cost reference to the output.

The shell must capture the command's output and maintain it as a shell string.

Later operations such as:

```bash
echo "${lots_table}" | grep ...
```

require that data to be expanded and passed through another process/pipeline.

When this happens repeatedly for many symbols, the data can be repeatedly copied, expanded, transferred, and processed.

Thus:

> **“The data is in memory” does not mean “the data is being processed without copying or process-transfer overhead.”**

The temporary-file version has a different access model:

```text
view_lots → temporary file → grep file
```

The shell does not need to expand the complete dataset each time, and programs such as `grep` can access the file directly.

---

## 7. Important Algorithmic Observation

The experiment also revealed a deeper issue.

Both v02 and v04 eliminate repeated execution of `view_lots`, but they still repeatedly scan the complete dataset for each HVT symbol.

Conceptually:

```text
generate dataset once
        ↓
scan dataset for symbol 1
scan dataset for symbol 2
scan dataset for symbol 3
...
scan dataset for symbol N
```

Therefore, the next major optimization is probably **not**:

> temporary file vs. Bash variable

but:

> **How can the dataset be processed once and grouped/indexed so that it does not need to be scanned N times?**

That suggests a future implementation based on a single-pass `awk` or `jq` transformation.

However, that optimization is deliberately outside this experiment.

---

## 8. Metrics

For this class of benchmark, the recommended interpretation is:

**`real`** — primary metric.

It answers:

> How long did the user actually wait?

**`user`** — diagnostic metric.

It indicates CPU time spent executing user-space code.

**`sys`** — diagnostic metric.

It indicates CPU time spent in kernel/system operations.

The three values should not be treated as interchangeable measures of “speed.”

In particular:

> `real ≠ user + sys`

is perfectly normal.

`real` measures elapsed time; `user` and `sys` measure CPU consumption.

---

## 9. Preliminary Rule of Thumb

Until this experiment is revisited, the following should be treated only as **working hypotheses**, not universal rules:

**Small control data**
→ Bash variables are appropriate.

**One-pass data**
→ Prefer pipelines/streaming.

**Large intermediate data used repeatedly**
→ Consider a temporary file or another reusable representation.

**Large data repeatedly scanned in its entirety**
→ Consider changing the algorithm rather than merely changing the storage representation.

The key principle is:

> **Choose the representation according to the access pattern, not simply according to whether the data resides in RAM or on disk.**

---

## 10. Future Experiment

A future dedicated experiment should systematically vary at least:

* dataset size;
* number of passes;
* number of downstream consumers;
* variable vs. temporary file;
* streaming pipeline;
* single-pass `awk`;
* single-pass `jq`;
* cold vs. warm filesystem cache;
* Cygwin environment and potentially native Linux for comparison.

The goal should be to establish practical crossover points such as:

> “For datasets of approximately X size and N repeated passes, representation A tends to outperform representation B.”

The final result could become a **Bash/system-scripting performance rule-of-thumb reference** for engineers working with AI-assisted development.

It should explicitly distinguish:

**storage location**,
**data movement**,
**process creation**,
**copying/expansion**,
**filesystem caching**, and
**algorithmic complexity**.

The experiment should therefore not begin with the assumption that one representation is inherently faster. Its purpose is to determine **when each representation becomes advantageous under a defined workload**.

---

### Open Question

The central question to preserve for the future is:

> **For a given dataset size and access pattern, when should an engineer use a Bash variable, a pipeline, a temporary file, or a single-pass processing algorithm—and what measurable factors indicate that it is time to switch?**

That is the experiment worth doing later.

For now, **v02 remains the empirically preferred implementation for `vl.hvti`**, while v04 remains attractive from a code/readability perspective but is not currently the fastest measured implementation. The performance question is deliberately left open rather than prematurely generalized.
