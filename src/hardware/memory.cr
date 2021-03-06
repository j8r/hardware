struct Hardware::Memory
  # VmallocTotal can be very huge - needs Int64
  getter meminfo = Hash(String, Int64).new

  def initialize
    File.read("/proc/meminfo").each_line do |line|
      properties = line.split ' '
      @meminfo[properties.first.rchop] = (properties.last == "kB" ? properties[-2] : properties.last).to_i64
    end
  end

  # in kB
  def total
    @meminfo["MemTotal"].to_i
  end

  # https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=34e431b0ae398fc54ea69ff85ec700722c9da773
  # MemAvailable can be not present in older systems
  def available
    if mem_available = @meminfo["MemAvailable"]?
      mem_available
    else
      @meminfo["MemFree"] - @meminfo["Buffers"] - @meminfo["Cached"] - @meminfo["SReclaimable"] - @meminfo["Shmem"]
    end.to_i
  end

  def used
    total - available
  end

  def percent(used = true)
    (used ? self.used : available).to_f32 * 100 / total
  end
end
