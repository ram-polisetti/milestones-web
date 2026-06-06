import React, { useEffect, useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import {
  ArrowLeft,
  BookOpen,
  Check,
  ChevronRight,
  CirclePlus,
  Flag,
  Gamepad2,
  Globe2,
  LayoutPanelLeft,
  Mail,
  Mic2,
  MoreHorizontal,
  Plus,
  Search,
  Settings,
  Smartphone,
  Tag,
  Trash2,
  X,
} from "lucide-react";
import "./styles.css";

const STORAGE_KEY = "milestones-local-v1";

const palette = {
  blue: "#1399f5",
  purple: "#b618c6",
  orange: "#ef8507",
  red: "#ef1748",
  coral: "#f02f32",
  green: "#18b954",
};

const iconMap = {
  phone: Smartphone,
  globe: Globe2,
  book: BookOpen,
  mail: Mail,
  mic: Mic2,
  game: Gamepad2,
};

const seed = {
  tags: ["Feature", "Bug", "Low", "Medium", "High", "Refactor"],
  projects: [
    {
      id: "ios",
      title: "iOS App",
      icon: "phone",
      color: palette.blue,
      status: "In Progress",
      milestones: [
        {
          id: "local-storage",
          title: "Local storage",
          status: "In Progress",
          accent: palette.green,
          tasks: [
            { id: "t1", title: "Define local schema", stage: "done", tags: ["Feature"] },
            { id: "t2", title: "Write migration plan", stage: "done", tags: ["Feature"] },
            { id: "t3", title: "Build import and export", stage: "progress", tags: ["Feature", "Medium"] },
            { id: "t4", title: "Add offline queue", stage: "progress", tags: ["Feature", "Medium"] },
            { id: "t5", title: "Polish storage UI", stage: "progress", tags: ["Low", "Refactor"] },
            { id: "t6", title: "Add settings toggle", stage: "todo", tags: ["Feature", "Low"] },
            { id: "t7", title: "Write telemetry events", stage: "todo", tags: ["Feature", "Medium"] },
            { id: "t8", title: "Design error states", stage: "todo", tags: ["Medium", "Bug"] },
            { id: "t9", title: "Track storage metrics", stage: "todo", tags: [] },
            { id: "t10", title: "Run release checklist", stage: "todo", tags: ["High"] },
          ],
        },
        { id: "onboarding", title: "Onboarding revamp", status: "Released", accent: palette.green, tasks: [] },
        { id: "paywall", title: "Paywall A/B test", status: "In Review", accent: "#f5ce42", tasks: [] },
        { id: "widgets", title: "Home screen widgets", status: "Planning", accent: palette.blue, tasks: [] },
        { id: "launch", title: "Launch on Product Hunt", status: "Draft", accent: "#a3a3a3", tasks: [] },
      ],
    },
    {
      id: "website",
      title: "Personal Website",
      icon: "globe",
      color: palette.purple,
      status: "Active",
      milestones: [
        {
          id: "launch-blog",
          title: "Launch blog",
          status: "Active",
          accent: palette.blue,
          tasks: [
            { id: "w1", title: "Choose a publishing stack", stage: "progress", tags: ["Feature"] },
            { id: "w2", title: "Draft the first article", stage: "todo", tags: [] },
            { id: "w3", title: "Design article template", stage: "todo", tags: ["Medium"] },
          ],
        },
      ],
    },
    {
      id: "book",
      title: "Side Project Book",
      icon: "book",
      color: palette.orange,
      status: "Idea",
      milestones: [
        {
          id: "outline",
          title: "Write outline",
          status: "Idea",
          accent: palette.blue,
          tasks: [{ id: "b1", title: "Collect chapter ideas", stage: "progress", tags: [] }],
        },
      ],
    },
    { id: "newsletter", title: "Newsletter", icon: "mail", color: palette.red, status: "Active", milestones: [] },
    { id: "podcast", title: "Podcast", icon: "mic", color: palette.coral, status: "In Progress", milestones: [] },
    { id: "game", title: "Indie Game", icon: "game", color: palette.green, status: "Idea", milestones: [] },
  ],
};

function cloneSeed() {
  return JSON.parse(JSON.stringify(seed));
}

function useStoredData() {
  const [data, setData] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY)) || cloneSeed();
    } catch {
      return cloneSeed();
    }
  });

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  }, [data]);

  return [data, setData];
}

function progress(milestone) {
  if (!milestone?.tasks.length) return 0;
  return Math.round((milestone.tasks.filter((task) => task.stage === "done").length / milestone.tasks.length) * 100);
}

function statusClass(status) {
  return status.toLowerCase().replaceAll(" ", "-");
}

function Badge({ children }) {
  return <span className={`badge ${statusClass(String(children))}`}>{children}</span>;
}

function AppIcon({ project, small = false }) {
  const Icon = iconMap[project.icon] || Smartphone;
  return (
    <span className={`app-icon ${small ? "small" : ""}`} style={{ background: project.color }}>
      <Icon size={small ? 17 : 24} strokeWidth={1.8} />
    </span>
  );
}

function Modal({ title, onClose, children }) {
  return (
    <div className="modal-backdrop" onMouseDown={onClose}>
      <section className="modal" onMouseDown={(event) => event.stopPropagation()}>
        <header>
          <h2>{title}</h2>
          <button className="icon-button" onClick={onClose} aria-label="Close">
            <X size={19} />
          </button>
        </header>
        {children}
      </section>
    </div>
  );
}

function ProjectForm({ onSubmit, onClose }) {
  const [title, setTitle] = useState("");
  const [icon, setIcon] = useState("phone");
  const [color, setColor] = useState(palette.blue);
  return (
    <form
      className="form"
      onSubmit={(event) => {
        event.preventDefault();
        if (title.trim()) onSubmit({ title: title.trim(), icon, color });
      }}
    >
      <label>
        Project name
        <input autoFocus value={title} onChange={(event) => setTitle(event.target.value)} placeholder="New project" />
      </label>
      <div className="form-label">Icon</div>
      <div className="choice-row">
        {Object.entries(iconMap).map(([key, Icon]) => (
          <button type="button" className={`choice ${icon === key ? "selected" : ""}`} onClick={() => setIcon(key)} key={key}>
            <Icon size={20} />
          </button>
        ))}
      </div>
      <div className="form-label">Color</div>
      <div className="choice-row">
        {Object.values(palette).map((value) => (
          <button
            type="button"
            aria-label={value}
            className={`color-choice ${color === value ? "selected" : ""}`}
            style={{ background: value }}
            onClick={() => setColor(value)}
            key={value}
          />
        ))}
      </div>
      <div className="form-actions">
        <button type="button" className="secondary-button" onClick={onClose}>Cancel</button>
        <button className="primary-button" type="submit">Create Project</button>
      </div>
    </form>
  );
}

function MilestoneForm({ onSubmit, onClose }) {
  const [title, setTitle] = useState("");
  const [status, setStatus] = useState("In Progress");
  return (
    <form
      className="form"
      onSubmit={(event) => {
        event.preventDefault();
        if (title.trim()) onSubmit({ title: title.trim(), status });
      }}
    >
      <label>
        Milestone name
        <input autoFocus value={title} onChange={(event) => setTitle(event.target.value)} placeholder="New milestone" />
      </label>
      <label>
        Status
        <select value={status} onChange={(event) => setStatus(event.target.value)}>
          <option>Planning</option>
          <option>In Progress</option>
          <option>In Review</option>
          <option>Released</option>
          <option>Draft</option>
        </select>
      </label>
      <div className="form-actions">
        <button type="button" className="secondary-button" onClick={onClose}>Cancel</button>
        <button className="primary-button" type="submit">Create Milestone</button>
      </div>
    </form>
  );
}

function SettingsPanel({ tags, onAddTag, onDeleteTag, onReset, onClose }) {
  const [tagName, setTagName] = useState("");
  return (
    <Modal title="Settings" onClose={onClose}>
      <div className="settings-section">
        <div className="section-label">GENERAL</div>
        <div className="settings-card">
          <div className="settings-row">
            <span className="settings-symbol blue"><Tag size={18} /></span>
            <strong>Tags</strong>
          </div>
          <form
            className="tag-form"
            onSubmit={(event) => {
              event.preventDefault();
              if (tagName.trim()) {
                onAddTag(tagName.trim());
                setTagName("");
              }
            }}
          >
            <input value={tagName} onChange={(event) => setTagName(event.target.value)} placeholder="New tag" />
            <button type="submit"><Plus size={18} /></button>
          </form>
          <div className="tag-list">
            {tags.map((tagNameItem) => (
              <span className="tag-chip" key={tagNameItem}>
                {tagNameItem}
                <button onClick={() => onDeleteTag(tagNameItem)} aria-label={`Delete ${tagNameItem}`}><X size={13} /></button>
              </span>
            ))}
          </div>
        </div>
      </div>
      <div className="settings-section">
        <div className="section-label">STORAGE</div>
        <div className="settings-card">
          <div className="settings-row">
            <span className="settings-symbol blue"><Smartphone size={18} /></span>
            <div>
              <strong>On this device</strong>
              <small>All data is saved locally in this browser.</small>
            </div>
          </div>
        </div>
      </div>
      <button className="danger-button" onClick={onReset}><Trash2 size={16} /> Reset sample data</button>
      <p className="settings-footnote">Milestones Local · No account · No cloud sync</p>
    </Modal>
  );
}

function ProjectSidebar({ projects, selectedId, onSelect, onAdd, onSettings, search, setSearch }) {
  return (
    <aside className="projects-pane">
      <div className="pane-toolbar">
        <h2>Projects</h2>
        <div>
          <button className="icon-button" onClick={onAdd} aria-label="New project"><Plus size={21} /></button>
          <button className="icon-button" onClick={onSettings} aria-label="Settings"><Settings size={20} /></button>
          <LayoutPanelLeft size={19} />
        </div>
      </div>
      <label className="search-box">
        <Search size={15} />
        <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search" />
      </label>
      <div className="project-list">
        {projects.map((project) => {
          const active = project.milestones[0];
          return (
            <button className={`project-row ${selectedId === project.id ? "selected" : ""}`} onClick={() => onSelect(project.id)} key={project.id}>
              <AppIcon project={project} />
              <span className="project-copy">
                <span className="row-title">
                  <strong>{project.title}</strong>
                  <Badge>{project.status}</Badge>
                </span>
                {active ? (
                  <>
                    <span className="active-milestone"><Flag size={12} fill="#169ff3" /> {active.title}</span>
                    <span className="mini-progress"><i style={{ width: `${progress(active)}%` }} /></span>
                  </>
                ) : (
                  <span className="empty-milestone">No active milestone</span>
                )}
              </span>
              {active && <span className="project-percent">{progress(active)}%</span>}
            </button>
          );
        })}
      </div>
      <button className="bottom-create" onClick={onAdd}><Plus size={20} /> New Project</button>
    </aside>
  );
}

function MilestonesPane({ project, selectedId, onSelect, onAdd, onBack }) {
  return (
    <section className="milestones-pane">
      <div className="mobile-nav">
        <button className="round-back" onClick={onBack}><ArrowLeft size={24} /></button>
      </div>
      <div className="milestone-heading">
        <div className="heading-project">
          <AppIcon project={project} small />
          <h1>{project.title}</h1>
        </div>
        <button className="icon-button more"><MoreHorizontal size={21} /></button>
      </div>
      <button className="backlog-row">
        <span><LayoutPanelLeft size={17} /> Backlog</span>
        <span>{project.milestones.reduce((count, item) => count + item.tasks.filter((task) => task.stage === "todo").length, 0)}</span>
      </button>
      <div className="subheading">
        <span>Milestones</span>
        <button onClick={onAdd}><Plus size={14} /> Add Milestone</button>
      </div>
      <div className="milestone-list">
        {project.milestones.map((milestone) => (
          <button
            className={`milestone-row ${selectedId === milestone.id ? "selected" : ""}`}
            onClick={() => onSelect(milestone.id)}
            key={milestone.id}
          >
            <span className="row-title">
              <strong><i className="status-dot" style={{ background: milestone.accent }} />{milestone.title}</strong>
              <Badge>{milestone.status}</Badge>
            </span>
            <span className="progress-track"><i style={{ width: `${progress(milestone)}%` }} /></span>
            <span className="progress-caption">
              <span>{milestone.tasks.filter((task) => task.stage === "done").length}/{milestone.tasks.length} tasks completed</span>
              <span>{progress(milestone)}%</span>
            </span>
          </button>
        ))}
        {!project.milestones.length && <div className="empty-state">No milestones yet.</div>}
      </div>
      <button className="bottom-create mobile-only" onClick={onAdd}><Plus size={20} /> New Milestone</button>
    </section>
  );
}

function TaskRow({ task, onToggle, onDelete, onMove }) {
  return (
    <div
      className={`task-row ${task.stage === "done" ? "complete" : ""}`}
      draggable
      onDragStart={(event) => {
        event.dataTransfer.effectAllowed = "move";
        event.dataTransfer.setData("text/plain", task.id);
      }}
    >
      <button className={`task-check ${task.stage}`} onClick={onToggle} aria-label={`Complete ${task.title}`}>
        {task.stage === "done" && <Check size={12} strokeWidth={3} />}
      </button>
      <div className="task-copy">
        <span>{task.title}</span>
        {!!task.tags.length && (
          <span className="task-tags">
            {task.tags.map((tagName) => <em key={tagName}>{tagName}</em>)}
          </span>
        )}
      </div>
      <select
        className="task-stage-select"
        aria-label={`Status for ${task.title}`}
        value={task.stage}
        onChange={(event) => onMove(event.target.value)}
        onClick={(event) => event.stopPropagation()}
      >
        <option value="todo">To Do</option>
        <option value="progress">In Progress</option>
        <option value="done">Done</option>
      </select>
      <button className="task-delete" onClick={onDelete} aria-label={`Delete ${task.title}`}><X size={14} /></button>
    </div>
  );
}

function TaskGroup({ title, stage, tasks, onToggle, onDelete, onMove }) {
  const [isDragOver, setIsDragOver] = useState(false);
  return (
    <section
      className={`task-group ${isDragOver ? "drag-over" : ""}`}
      onDragOver={(event) => {
        event.preventDefault();
        event.dataTransfer.dropEffect = "move";
        setIsDragOver(true);
      }}
      onDragLeave={(event) => {
        if (!event.currentTarget.contains(event.relatedTarget)) setIsDragOver(false);
      }}
      onDrop={(event) => {
        event.preventDefault();
        setIsDragOver(false);
        const taskId = event.dataTransfer.getData("text/plain");
        if (taskId) onMove(taskId, stage);
      }}
    >
      <h3>{title}<span>{tasks.length}</span></h3>
      <div className="task-card">
        {tasks.map((task) => (
          <TaskRow
            task={task}
            onToggle={() => onToggle(task.id)}
            onDelete={() => onDelete(task.id)}
            onMove={(nextStage) => onMove(task.id, nextStage)}
            key={task.id}
          />
        ))}
        {!tasks.length && <div className="empty-column">Drop tasks here</div>}
      </div>
    </section>
  );
}

function TasksPane({ milestone, tags, onAddTask, onToggle, onDelete, onMove, onBack }) {
  const [title, setTitle] = useState("");
  const [selectedTag, setSelectedTag] = useState("");
  const grouped = {
    progress: milestone.tasks.filter((task) => task.stage === "progress"),
    todo: milestone.tasks.filter((task) => task.stage === "todo"),
    done: milestone.tasks.filter((task) => task.stage === "done"),
  };
  const submit = (event) => {
    event.preventDefault();
    if (!title.trim()) return;
    onAddTask(title.trim(), selectedTag ? [selectedTag] : []);
    setTitle("");
    setSelectedTag("");
  };
  return (
    <main className="tasks-pane">
      <div className="mobile-nav">
        <button className="round-back" onClick={onBack}><ArrowLeft size={24} /></button>
      </div>
      <div className="tasks-scroll">
        <h1>{milestone.title}</h1>
        <form className="quick-add" onSubmit={submit}>
          <input value={title} onChange={(event) => setTitle(event.target.value)} placeholder="Add a new task..." />
          <select aria-label="Task tag" value={selectedTag} onChange={(event) => setSelectedTag(event.target.value)}>
            <option value="">No tag</option>
            {tags.map((tagName) => <option key={tagName}>{tagName}</option>)}
          </select>
          <button type="submit" aria-label="Add task"><CirclePlus size={21} /></button>
        </form>
        <div className="kanban-board">
          <TaskGroup title="To Do" stage="todo" tasks={grouped.todo} onToggle={onToggle} onDelete={onDelete} onMove={onMove} />
          <TaskGroup title="In Progress" stage="progress" tasks={grouped.progress} onToggle={onToggle} onDelete={onDelete} onMove={onMove} />
          <TaskGroup title="Done" stage="done" tasks={grouped.done} onToggle={onToggle} onDelete={onDelete} onMove={onMove} />
        </div>
        {!milestone.tasks.length && <div className="empty-state large">Add the first task to this milestone.</div>}
      </div>
      <form className="mobile-task-add" onSubmit={submit}>
        <input value={title} onChange={(event) => setTitle(event.target.value)} placeholder="Add a new task..." />
      </form>
    </main>
  );
}

function App() {
  const [data, setData] = useStoredData();
  const [selectedProjectId, setSelectedProjectId] = useState(data.projects[0]?.id);
  const selectedProject = data.projects.find((project) => project.id === selectedProjectId) || data.projects[0];
  const [selectedMilestoneId, setSelectedMilestoneId] = useState(selectedProject?.milestones[0]?.id);
  const selectedMilestone = selectedProject?.milestones.find((item) => item.id === selectedMilestoneId) || selectedProject?.milestones[0];
  const [modal, setModal] = useState(null);
  const [mobileView, setMobileView] = useState("projects");
  const [search, setSearch] = useState("");

  useEffect(() => {
    if (selectedProject && !selectedProject.milestones.some((item) => item.id === selectedMilestoneId)) {
      setSelectedMilestoneId(selectedProject.milestones[0]?.id);
    }
  }, [selectedProjectId]);

  const filteredProjects = useMemo(
    () => data.projects.filter((project) => project.title.toLowerCase().includes(search.toLowerCase())),
    [data.projects, search],
  );

  const updateMilestone = (projectId, milestoneId, updater) => {
    setData((current) => ({
      ...current,
      projects: current.projects.map((project) =>
        project.id !== projectId
          ? project
          : { ...project, milestones: project.milestones.map((item) => (item.id === milestoneId ? updater(item) : item)) },
      ),
    }));
  };

  const selectProject = (id) => {
    const project = data.projects.find((item) => item.id === id);
    setSelectedProjectId(id);
    setSelectedMilestoneId(project?.milestones[0]?.id);
    setMobileView("milestones");
  };

  const selectMilestone = (id) => {
    setSelectedMilestoneId(id);
    setMobileView("tasks");
  };

  const createProject = ({ title, icon, color }) => {
    const id = crypto.randomUUID();
    setData((current) => ({
      ...current,
      projects: [...current.projects, { id, title, icon, color, status: "Active", milestones: [] }],
    }));
    setSelectedProjectId(id);
    setSelectedMilestoneId(undefined);
    setModal(null);
  };

  const createMilestone = ({ title, status }) => {
    const id = crypto.randomUUID();
    setData((current) => ({
      ...current,
      projects: current.projects.map((project) =>
        project.id === selectedProject.id
          ? { ...project, milestones: [...project.milestones, { id, title, status, accent: palette.blue, tasks: [] }] }
          : project,
      ),
    }));
    setSelectedMilestoneId(id);
    setModal(null);
  };

  const addTask = (title, taskTags) => {
    updateMilestone(selectedProject.id, selectedMilestone.id, (milestone) => ({
      ...milestone,
      tasks: [{ id: crypto.randomUUID(), title, stage: "todo", tags: taskTags }, ...milestone.tasks],
    }));
  };

  const toggleTask = (taskId) => {
    updateMilestone(selectedProject.id, selectedMilestone.id, (milestone) => ({
      ...milestone,
      tasks: milestone.tasks.map((task) => {
        if (task.id !== taskId) return task;
        const stage = task.stage === "done" ? "todo" : "done";
        return { ...task, stage };
      }),
    }));
  };

  const deleteTask = (taskId) => {
    updateMilestone(selectedProject.id, selectedMilestone.id, (milestone) => ({
      ...milestone,
      tasks: milestone.tasks.filter((task) => task.id !== taskId),
    }));
  };

  const moveTask = (taskId, stage) => {
    updateMilestone(selectedProject.id, selectedMilestone.id, (milestone) => ({
      ...milestone,
      tasks: milestone.tasks.map((task) => (task.id === taskId ? { ...task, stage } : task)),
    }));
  };

  return (
    <div className={`app-shell mobile-${mobileView}`}>
      <ProjectSidebar
        projects={filteredProjects}
        selectedId={selectedProject?.id}
        onSelect={selectProject}
        onAdd={() => setModal("project")}
        onSettings={() => setModal("settings")}
        search={search}
        setSearch={setSearch}
      />
      {selectedProject && (
        <MilestonesPane
          project={selectedProject}
          selectedId={selectedMilestone?.id}
          onSelect={selectMilestone}
          onAdd={() => setModal("milestone")}
          onBack={() => setMobileView("projects")}
        />
      )}
      {selectedMilestone ? (
        <TasksPane
          milestone={selectedMilestone}
          tags={data.tags}
          onAddTask={addTask}
          onToggle={toggleTask}
          onDelete={deleteTask}
          onMove={moveTask}
          onBack={() => setMobileView("milestones")}
        />
      ) : (
        <main className="tasks-pane empty-detail">
          <Flag size={38} />
          <h2>Select or create a milestone</h2>
        </main>
      )}
      {modal === "project" && <Modal title="New Project" onClose={() => setModal(null)}><ProjectForm onSubmit={createProject} onClose={() => setModal(null)} /></Modal>}
      {modal === "milestone" && selectedProject && <Modal title="New Milestone" onClose={() => setModal(null)}><MilestoneForm onSubmit={createMilestone} onClose={() => setModal(null)} /></Modal>}
      {modal === "settings" && (
        <SettingsPanel
          tags={data.tags}
          onAddTag={(tagName) => setData((current) => ({ ...current, tags: current.tags.includes(tagName) ? current.tags : [...current.tags, tagName] }))}
          onDeleteTag={(tagName) => setData((current) => ({ ...current, tags: current.tags.filter((item) => item !== tagName) }))}
          onReset={() => {
            const fresh = cloneSeed();
            setData(fresh);
            setSelectedProjectId(fresh.projects[0].id);
            setSelectedMilestoneId(fresh.projects[0].milestones[0].id);
            setModal(null);
          }}
          onClose={() => setModal(null)}
        />
      )}
    </div>
  );
}

createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
