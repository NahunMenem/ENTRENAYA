"use client";
import { useCallback, useEffect, useState } from "react";
import {
  Activity,
  ArrowDown,
  ArrowUp,
  BookOpen,
  Check,
  ChevronRight,
  ClipboardList,
  Dumbbell,
  LayoutDashboard,
  LogOut,
  Pencil,
  Plus,
  Play,
  Search,
  Trash2,
  Video,
  X,
} from "lucide-react";

type Exercise = {
  id: string;
  name: string;
  muscle_group: string;
  equipment: string;
  instructions: string;
  video_url: string | null;
  cover_url?: string | null;
  cover_image?: string | null;
  remove_cover?: boolean;
  published: boolean;
};
type Step = {
  id: string;
  name?: string;
  sets: number;
  reps: number;
  rest_seconds: number;
};
type Routine = {
  id: string;
  name: string;
  category: string;
  level: string;
  description: string;
  days: number[];
  exercises: Step[];
  published: boolean;
};
const categories = [
  "Hipertrofia",
  "Déficit",
  "Volumen",
  "Fuerza",
  "Mantenimiento",
];
const days = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
const newExercise = (): Exercise => ({
  id: "",
  name: "",
  muscle_group: "Pecho",
  equipment: "",
  instructions: "",
  video_url: null,
  published: false,
});
const newRoutine = (): Routine => ({
  id: "",
  name: "",
  category: "Hipertrofia",
  level: "Principiante",
  description: "",
  days: [],
  exercises: [],
  published: false,
});
async function api(path: string, method = "GET", body?: unknown) {
  const response = await fetch(`/api/manage/${path}`, {
    method,
    headers: { "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
    cache: "no-store",
  });
  const data = await response.json();
  if (response.status === 401) {
    window.location.href = "/login";
    throw new Error("La sesión venció.");
  }
  if (!response.ok)
    throw new Error(
      typeof data.detail === "string"
        ? data.detail
        : Array.isArray(data.detail)
          ? data.detail.map((e: { msg: string }) => e.msg).join(". ")
          : "No pudimos guardar los cambios.",
    );
  return data;
}
export default function Dashboard({
  demoMode = false,
}: {
  demoMode?: boolean;
}) {
  const [tab, setTab] = useState("Resumen");
  const [exercises, setExercises] = useState<Exercise[]>([]);
  const [routines, setRoutines] = useState<Routine[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [query, setQuery] = useState("");
  const [filter, setFilter] = useState("Todos");
  const [exercise, setExercise] = useState<Exercise | null>(null);
  const [routine, setRoutine] = useState<Routine | null>(null);
  const [saving, setSaving] = useState(false);
  const [picker, setPicker] = useState("");
  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const [e, r] = await Promise.all([api("exercises"), api("routines")]);
      setExercises(e);
      setRoutines(r);
    } catch (e) {
      setError(
        e instanceof Error ? e.message : "No pudimos cargar el contenido.",
      );
    } finally {
      setLoading(false);
    }
  }, []);
  useEffect(() => {
    void load();
  }, [load]);
  useEffect(() => {
    if (!exercise && !routine) return;
    const close = (e: KeyboardEvent) => {
      if (e.key === "Escape" && !saving) {
        setExercise(null);
        setRoutine(null);
      }
    };
    document.addEventListener("keydown", close);
    return () => document.removeEventListener("keydown", close);
  }, [exercise, routine, saving]);
  function navigate(value: string) {
    setTab(value);
    setQuery("");
    setFilter("Todos");
    setNotice("");
  }
  async function save(
    kind: "exercises" | "routines",
    data: Exercise | Routine,
  ) {
    setSaving(true);
    setError("");
    setNotice("");
    try {
      await api(
        `${kind}${data.id ? `/${data.id}` : ""}`,
        data.id ? "PUT" : "POST",
        data,
      );
      setExercise(null);
      setRoutine(null);
      setNotice(
        data.published
          ? "Contenido publicado. Ya está disponible para la app."
          : "Borrador guardado. Todavía no aparece en la app.",
      );
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "No pudimos guardar.");
    } finally {
      setSaving(false);
    }
  }
  function move(index: number, offset: number) {
    if (!routine) return;
    const items = [...routine.exercises];
    const [item] = items.splice(index, 1);
    items.splice(index + offset, 0, item);
    setRoutine({ ...routine, exercises: items });
  }
  const visibleExercises = exercises.filter(
    (e) =>
      e.name.toLocaleLowerCase().includes(query.toLocaleLowerCase()) &&
      (filter === "Todos" || e.muscle_group === filter),
  );
  const visibleRoutines = routines.filter(
    (e) =>
      e.name.toLocaleLowerCase().includes(query.toLocaleLowerCase()) &&
      (filter === "Todos" || e.category === filter),
  );
  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">
          <i>
            <Dumbbell />
          </i>
          Entrena<span>Ya</span>
        </div>
        <div className="workspace">MONITOREO · ADMINISTRACIÓN</div>
        <nav>
          {[
            [LayoutDashboard, "Resumen"],
            [BookOpen, "Ejercicios"],
            [ClipboardList, "Rutinas"],
          ].map(([Icon, label]) => {
            const I = Icon as typeof LayoutDashboard;
            const text = String(label);
            return (
              <button
                key={text}
                className={tab === text ? "active" : ""}
                onClick={() => navigate(text)}
              >
                <I size={19} />
                {text}
                <ChevronRight size={15} />
              </button>
            );
          })}
        </nav>
        <div className="sidebar-note">
          <Activity size={22} />
          <strong>Del panel a la app</strong>
          <p>
            Publicá tu contenido cuando esté listo para acompañar cada
            entrenamiento.
          </p>
          <span>
            <b /> API conectada al proyecto
          </span>
        </div>
        {!demoMode && (
          <button
            className="logout"
            onClick={async () => {
              await fetch("/api/session", { method: "DELETE" });
              window.location.href = "/login";
            }}
          >
            <LogOut size={17} />
            Cerrar sesión
          </button>
        )}
      </aside>
      <main className="content">
        <header className="topbar">
          <span>
            Administración <ChevronRight size={14} /> {tab}
          </span>
          <div className="operator">
            <span>A</span>
            <div>
              Administrador
              <small>
                {demoMode ? "Acceso temporal sin contraseña" : "EntrenaYa"}
              </small>
            </div>
          </div>
        </header>
        <section className="page">
          {demoMode && (
            <div className="demo-banner">Acceso temporal sin contraseña</div>
          )}
          <div className="page-heading">
            <div>
              <div className="eyebrow">GESTIÓN DE CONTENIDO</div>
              <h1>
                {tab === "Resumen"
                  ? "Todo listo para el próximo entrenamiento."
                  : tab === "Ejercicios"
                    ? "Biblioteca de ejercicios"
                    : "Rutinas para tu comunidad"}
              </h1>
              <p>
                {tab === "Resumen"
                  ? "Creá, organizá y publicá el contenido que tus usuarios llevan al gimnasio."
                  : tab === "Ejercicios"
                    ? "Cada movimiento, bien explicado. Administrá los ejercicios que aparecen en la app."
                    : "Planes con un objetivo claro, listos para que cada usuario los adapte a su semana."}
              </p>
            </div>
            <button
              onClick={() =>
                tab === "Ejercicios"
                  ? setExercise(newExercise())
                  : setRoutine(newRoutine())
              }
            >
              <Plus size={18} />
              {tab === "Ejercicios" ? "Nuevo ejercicio" : "Nueva rutina"}
            </button>
          </div>
          {error && !exercise && !routine && (
            <div className="error" role="alert">
              {error}
              <button className="text-button" onClick={load}>
                Reintentar
              </button>
            </div>
          )}
          {notice && (
            <div className="success" role="status">
              <Check size={18} />
              {notice}
            </div>
          )}
          {loading ? (
            <div className="empty">Cargando contenido…</div>
          ) : tab === "Resumen" ? (
            <>
              <div className="stats">
                {[
                  [BookOpen, exercises.length, "Ejercicios en biblioteca"],
                  [
                    Video,
                    exercises.filter((e) => e.video_url).length,
                    "Con video de técnica",
                  ],
                  [ClipboardList, routines.length, "Rutinas creadas"],
                  [
                    Activity,
                    routines.filter((e) => e.published).length,
                    "Rutinas publicadas",
                  ],
                ].map(([Icon, number, label]) => {
                  const I = Icon as typeof Activity;
                  return (
                    <article key={String(label)}>
                      <div className="stat-icon">
                        <I size={21} />
                      </div>
                      <strong>{String(number)}</strong>
                      <span>{String(label)}</span>
                    </article>
                  );
                })}
              </div>
              <div className="hero-panel">
                <div>
                  <span className="eyebrow">
                    UNA BIBLIOTECA QUE CRECE CON VOS
                  </span>
                  <h2>
                    Mejores instrucciones.
                    <br />
                    Más confianza al entrenar.
                  </h2>
                  <p>
                    Agregá indicaciones, equipamiento y un video de técnica. Tus
                    usuarios van a encontrarlos justo cuando los necesitan.
                  </p>
                  <button
                    onClick={() => {
                      navigate("Ejercicios");
                      setExercise(newExercise());
                    }}
                  >
                    <Plus size={17} />
                    Crear ejercicio
                  </button>
                </div>
                <Dumbbell className="hero-icon" />
              </div>
              <div className="section-heading">
                <h2>Rutinas del catálogo</h2>
                <button
                  className="text-button"
                  onClick={() => navigate("Rutinas")}
                >
                  Ver todas <ChevronRight size={16} />
                </button>
              </div>
              {routines.length === 0 ? (
                <div className="empty">
                  Todavía no creaste rutinas. Empezá con una categoría y sumá
                  ejercicios de tu biblioteca.
                </div>
              ) : (
                <div className="routine-grid">
                  {routines.slice(0, 4).map((r) => (
                    <RoutineCard
                      key={r.id}
                      routine={r}
                      onEdit={() => setRoutine(r)}
                    />
                  ))}
                </div>
              )}
            </>
          ) : (
            <>
              <div className="toolbar">
                <div className="search">
                  <Search size={18} />
                  <input
                    aria-label="Buscar"
                    placeholder={
                      tab === "Ejercicios"
                        ? "Buscar ejercicio…"
                        : "Buscar rutina…"
                    }
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                  />
                </div>
                <select
                  aria-label="Filtrar categoría"
                  value={filter}
                  onChange={(e) => setFilter(e.target.value)}
                >
                  {[
                    "Todos",
                    ...(tab === "Ejercicios"
                      ? [...new Set(exercises.map((e) => e.muscle_group))]
                      : categories),
                  ].map((v) => (
                    <option key={v}>{v}</option>
                  ))}
                </select>
                <span>
                  {tab === "Ejercicios"
                    ? visibleExercises.length
                    : visibleRoutines.length}{" "}
                  resultados
                </span>
              </div>
              {tab === "Ejercicios" ? (
                <div className="table-wrap">
                  <table>
                    <thead>
                      <tr>
                        <th>Ejercicio</th>
                        <th>Grupo muscular</th>
                        <th>Video</th>
                        <th>Estado</th>
                        <th />
                      </tr>
                    </thead>
                    <tbody>
                      {visibleExercises.map((e) => (
                        <tr key={e.id}>
                          <td>
                            {e.cover_url && (
                              <img
                                className="exercise-thumb"
                                src={e.cover_url}
                                alt=""
                              />
                            )}
                            <strong>{e.name}</strong>
                            <small>
                              {e.equipment || "Sin equipamiento indicado"}
                            </small>
                          </td>
                          <td>{e.muscle_group}</td>
                          <td>
                            {e.video_url ? (
                              <span className="video-tag">
                                <Video size={15} />
                                Disponible
                              </span>
                            ) : (
                              <span className="muted">Sin video</span>
                            )}
                          </td>
                          <td>
                            <Status published={e.published} />
                          </td>
                          <td>
                            <button
                              className="icon-button"
                              aria-label={`Editar ${e.name}`}
                              onClick={() => {
                                setError("");
                                setExercise(e);
                              }}
                            >
                              <Pencil size={17} />
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  {!visibleExercises.length && (
                    <div className="empty">
                      No hay ejercicios para esta búsqueda.
                    </div>
                  )}
                </div>
              ) : (
                <div className="routine-grid">
                  {visibleRoutines.map((r) => (
                    <RoutineCard
                      key={r.id}
                      routine={r}
                      onEdit={() => {
                        setError("");
                        setRoutine(r);
                      }}
                    />
                  ))}
                  {!visibleRoutines.length && (
                    <div className="empty">
                      No hay rutinas para esta búsqueda.
                    </div>
                  )}
                </div>
              )}
            </>
          )}
        </section>
      </main>
      {(exercise || routine) && (
        <div className="modal-backdrop">
          <section
            className="editor"
            role="dialog"
            aria-modal="true"
            aria-labelledby="editor-title"
          >
            <header>
              <div>
                <span className="eyebrow">
                  {exercise ? "BIBLIOTECA" : "CATÁLOGO DE RUTINAS"}
                </span>
                <h2 id="editor-title">
                  {exercise
                    ? exercise.id
                      ? "Editar ejercicio"
                      : "Nuevo ejercicio"
                    : routine?.id
                      ? "Editar rutina"
                      : "Nueva rutina"}
                </h2>
              </div>
              <button
                className="icon-button"
                aria-label="Cerrar editor"
                disabled={saving}
                onClick={() => {
                  setExercise(null);
                  setRoutine(null);
                  setError("");
                }}
              >
                <X />
              </button>
            </header>
            <form
              onSubmit={(e) => {
                e.preventDefault();
                if (exercise) void save("exercises", exercise);
                else if (routine) {
                  if (!routine.days.length || !routine.exercises.length) {
                    setError("Elegí al menos un día y un ejercicio.");
                    return;
                  }
                  void save("routines", routine);
                }
              }}
            >
              <fieldset disabled={saving}>
                {exercise ? (
                  <>
                    <label>
                      Nombre del ejercicio
                      <input
                        autoFocus
                        required
                        minLength={2}
                        maxLength={255}
                        value={exercise.name}
                        onChange={(e) =>
                          setExercise({ ...exercise, name: e.target.value })
                        }
                        placeholder="Ej.: Press de banca"
                      />
                    </label>
                    <div className="form-row">
                      <label>
                        Grupo muscular
                        <select
                          value={exercise.muscle_group}
                          onChange={(e) =>
                            setExercise({
                              ...exercise,
                              muscle_group: e.target.value,
                            })
                          }
                        >
                          {[
                            ...new Set([
                              "Pecho",
                              "Espalda",
                              "Piernas",
                              "Hombros",
                              "Brazos",
                              "Abdominales",
                              "Otros",
                              exercise.muscle_group,
                            ]),
                          ].map((v) => (
                            <option key={v}>{v}</option>
                          ))}
                        </select>
                      </label>
                      <label>
                        Equipamiento
                        <input
                          maxLength={120}
                          value={exercise.equipment}
                          onChange={(e) =>
                            setExercise({
                              ...exercise,
                              equipment: e.target.value,
                            })
                          }
                          placeholder="Barra, mancuernas…"
                        />
                      </label>
                    </div>
                    <label>
                      Foto de portada
                      <input
                        type="file"
                        key={`${exercise.id}-${exercise.remove_cover ? "removed" : "active"}`}
                        accept="image/jpeg,image/png,image/webp"
                        onChange={async (event) => {
                          const file = event.target.files?.[0];
                          if (!file) return;
                          if (file.size > 4 * 1024 * 1024) {
                            setError("La foto debe pesar hasta 4 MB.");
                            event.target.value = "";
                            return;
                          }
                          const id = exercise.id;
                          try {
                            const data = await new Promise<string>(
                              (resolve, reject) => {
                                const reader = new FileReader();
                                reader.onload = () =>
                                  resolve(String(reader.result));
                                reader.onerror = reject;
                                reader.readAsDataURL(file);
                              },
                            );
                            setExercise((current) =>
                              current?.id === id
                                ? {
                                    ...current,
                                    cover_image: data,
                                    remove_cover: false,
                                  }
                                : current,
                            );
                            setError("");
                          } catch {
                            setError(
                              "No pudimos abrir la foto. Probá con otra imagen.",
                            );
                          }
                        }}
                      />
                      <small>
                        Elegí una foto JPG, PNG o WebP de hasta 4 MB. Se guarda
                        al tocar Guardar cambios.
                      </small>
                    </label>
                    {(exercise.cover_image ||
                      (exercise.cover_url && !exercise.remove_cover)) && (
                      <div className="cover-preview">
                        <img
                          src={exercise.cover_image || exercise.cover_url!}
                          alt={`Portada de ${exercise.name || "ejercicio"}`}
                        />
                        {exercise.video_url && (
                          <span className="cover-play">
                            <Play size={28} />
                          </span>
                        )}
                      </div>
                    )}
                    {(exercise.cover_image || exercise.cover_url) &&
                      !exercise.remove_cover && (
                        <button
                          type="button"
                          className="secondary"
                          onClick={() =>
                            setExercise({
                              ...exercise,
                              cover_image: null,
                              remove_cover: true,
                            })
                          }
                        >
                          Quitar portada
                        </button>
                      )}
                    <label>
                      Cómo realizarlo
                      <textarea
                        rows={5}
                        maxLength={10000}
                        value={exercise.instructions}
                        onChange={(e) =>
                          setExercise({
                            ...exercise,
                            instructions: e.target.value,
                          })
                        }
                        placeholder="Posición inicial, recorrido y detalles de la técnica…"
                      />
                    </label>
                    <label>
                      Video de técnica · URL HTTPS
                      <input
                        type="url"
                        pattern="https://.*"
                        value={exercise.video_url || ""}
                        onChange={(e) =>
                          setExercise({
                            ...exercise,
                            video_url: e.target.value || null,
                          })
                        }
                        placeholder="https://…/ejercicio.mp4"
                      />
                      <small>
                        Enlace directo al video alojado, no a una página de
                        YouTube. La subida de archivos se configurará con el
                        almacenamiento.
                      </small>
                    </label>
                    {exercise.video_url?.startsWith("https://") && (
                      <video
                        className="video-preview"
                        src={exercise.video_url}
                        controls
                        preload="none"
                      />
                    )}
                    <label className="toggle">
                      <input
                        type="checkbox"
                        checked={exercise.published}
                        onChange={(e) =>
                          setExercise({
                            ...exercise,
                            published: e.target.checked,
                          })
                        }
                      />
                      <span>
                        <strong>Publicado en la app</strong>
                        <small>Al desactivarlo queda como borrador.</small>
                      </span>
                    </label>
                  </>
                ) : (
                  routine && (
                    <>
                      <label>
                        Nombre de la rutina
                        <input
                          autoFocus
                          required
                          minLength={2}
                          maxLength={100}
                          value={routine.name}
                          onChange={(e) =>
                            setRoutine({ ...routine, name: e.target.value })
                          }
                          placeholder="Ej.: Hipertrofia · tren superior"
                        />
                      </label>
                      <div className="form-row">
                        <label>
                          Categoría
                          <select
                            value={routine.category}
                            onChange={(e) =>
                              setRoutine({
                                ...routine,
                                category: e.target.value,
                              })
                            }
                          >
                            {categories.map((v) => (
                              <option key={v}>{v}</option>
                            ))}
                          </select>
                        </label>
                        <label>
                          Nivel
                          <select
                            value={routine.level}
                            onChange={(e) =>
                              setRoutine({ ...routine, level: e.target.value })
                            }
                          >
                            {["Principiante", "Intermedio", "Avanzado"].map(
                              (v) => (
                                <option key={v}>{v}</option>
                              ),
                            )}
                          </select>
                        </label>
                      </div>
                      <label>
                        Descripción
                        <textarea
                          rows={3}
                          maxLength={5000}
                          value={routine.description}
                          onChange={(e) =>
                            setRoutine({
                              ...routine,
                              description: e.target.value,
                            })
                          }
                          placeholder="Objetivo y recomendaciones para esta rutina…"
                        />
                      </label>
                      <label>Días sugeridos</label>
                      <div className="day-picker">
                        {days.map((day, index) => (
                          <button
                            type="button"
                            key={day}
                            aria-pressed={routine.days.includes(index + 1)}
                            className={
                              routine.days.includes(index + 1) ? "selected" : ""
                            }
                            onClick={() =>
                              setRoutine({
                                ...routine,
                                days: routine.days.includes(index + 1)
                                  ? routine.days.filter((d) => d !== index + 1)
                                  : [...routine.days, index + 1].sort(),
                              })
                            }
                          >
                            {day}
                          </button>
                        ))}
                      </div>
                      <div className="section-heading">
                        <h3>Ejercicios · {routine.exercises.length}</h3>
                        <small>En orden de entrenamiento</small>
                      </div>
                      {routine.exercises.map((step, index) => (
                        <div className="routine-step" key={step.id}>
                          <div className="step-heading">
                            <strong>
                              {index + 1}.{" "}
                              {exercises.find((e) => e.id === step.id)?.name ||
                                step.name}
                            </strong>
                            <div>
                              <button
                                type="button"
                                className="icon-button"
                                aria-label="Subir"
                                disabled={!index}
                                onClick={() => move(index, -1)}
                              >
                                <ArrowUp size={16} />
                              </button>
                              <button
                                type="button"
                                className="icon-button"
                                aria-label="Bajar"
                                disabled={
                                  index === routine.exercises.length - 1
                                }
                                onClick={() => move(index, 1)}
                              >
                                <ArrowDown size={16} />
                              </button>
                              <button
                                type="button"
                                className="icon-button"
                                aria-label="Quitar ejercicio"
                                onClick={() =>
                                  setRoutine({
                                    ...routine,
                                    exercises: routine.exercises.filter(
                                      (e) => e.id !== step.id,
                                    ),
                                  })
                                }
                              >
                                <Trash2 size={16} />
                              </button>
                            </div>
                          </div>
                          <div className="form-row triple">
                            {[
                              ["sets", "Series", 1, 10],
                              ["reps", "Repeticiones", 1, 50],
                              ["rest_seconds", "Descanso (s)", 0, 300],
                            ].map(([key, label, min, max]) => (
                              <label key={key}>
                                {label}
                                <input
                                  type="number"
                                  required
                                  min={Number(min)}
                                  max={Number(max)}
                                  value={step[key as keyof Step]}
                                  onChange={(e) =>
                                    setRoutine({
                                      ...routine,
                                      exercises: routine.exercises.map(
                                        (s, i) =>
                                          i === index
                                            ? {
                                                ...s,
                                                [String(key)]: Number(
                                                  e.target.value,
                                                ),
                                              }
                                            : s,
                                      ),
                                    })
                                  }
                                />
                              </label>
                            ))}
                          </div>
                        </div>
                      ))}
                      <div className="add-exercise">
                        <div className="search">
                          <Search size={16} />
                          <input
                            aria-label="Buscar ejercicio para agregar"
                            placeholder="Buscar en la biblioteca…"
                            value={picker}
                            onChange={(e) => setPicker(e.target.value)}
                          />
                        </div>
                        <select
                          aria-label="Agregar ejercicio"
                          value=""
                          onChange={(e) => {
                            const item = exercises.find(
                              (x) => x.id === e.target.value,
                            );
                            if (item)
                              setRoutine({
                                ...routine,
                                exercises: [
                                  ...routine.exercises,
                                  {
                                    id: item.id,
                                    sets: 3,
                                    reps: 12,
                                    rest_seconds: 90,
                                  },
                                ],
                              });
                          }}
                        >
                          <option value="">+ Agregar ejercicio</option>
                          {exercises
                            .filter(
                              (e) =>
                                !routine.exercises.some((s) => s.id === e.id) &&
                                e.name
                                  .toLowerCase()
                                  .includes(picker.toLowerCase()),
                            )
                            .map((e) => (
                              <option key={e.id} value={e.id}>
                                {e.name}
                                {e.published ? "" : " · borrador"}
                              </option>
                            ))}
                        </select>
                      </div>
                      <label className="toggle">
                        <input
                          type="checkbox"
                          checked={routine.published}
                          onChange={(e) =>
                            setRoutine({
                              ...routine,
                              published: e.target.checked,
                            })
                          }
                        />
                        <span>
                          <strong>Publicar rutina en la app</strong>
                          <small>
                            Todos sus ejercicios deben estar publicados.
                          </small>
                        </span>
                      </label>
                    </>
                  )
                )}
              </fieldset>
              {error && (
                <div className="error" role="alert">
                  {error}
                </div>
              )}
              <footer>
                <button
                  type="button"
                  className="secondary"
                  disabled={saving}
                  onClick={() => {
                    setExercise(null);
                    setRoutine(null);
                    setError("");
                  }}
                >
                  Cancelar
                </button>
                <button disabled={saving}>
                  <Check size={17} />
                  {saving ? "Guardando…" : "Guardar cambios"}
                </button>
              </footer>
            </form>
          </section>
        </div>
      )}
    </div>
  );
}
function Status({ published }: { published: boolean }) {
  return (
    <span className={`status ${published ? "published" : ""}`}>
      <b />
      {published ? "Publicado" : "Borrador"}
    </span>
  );
}
function RoutineCard({
  routine,
  onEdit,
}: {
  routine: Routine;
  onEdit: () => void;
}) {
  return (
    <article className="routine-card">
      <div>
        <span className="category">{routine.category}</span>
        <Status published={routine.published} />
      </div>
      <h3>{routine.name}</h3>
      <p>{routine.description || "Sin descripción todavía."}</p>
      <div className="routine-meta">
        {routine.level} · {routine.exercises.length} ejercicios
      </div>
      <div className="card-days">
        {days.map((day, index) => (
          <span
            className={routine.days.includes(index + 1) ? "selected" : ""}
            key={day}
          >
            {day}
          </span>
        ))}
      </div>
      <button className="secondary" onClick={onEdit}>
        <Pencil size={15} />
        Editar rutina
      </button>
    </article>
  );
}
